class Search < ActiveRecord::Base
  serialize :history, Array

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :with_user, lambda { |arg| where( "searches.user_id = ? or searches.id in (select query_users.search_id from query_users where query_users.user_id = ?)", arg, arg ).references(:query_users) }

  # Model Validation
  validates_presence_of :name

  # Model Relationships
  belongs_to :user
  belongs_to :identifier_concept, class_name: "Concept"

  has_many :criteria, -> { where( deleted: false ).order('position') }
  has_many :concepts, -> { order "criteria.position" }, through: :criteria

  has_many :query_sources, dependent: :destroy
  has_many :sources, -> { order :name }, through: :query_sources

  has_many :reports

  has_many :true_datasets, -> { where(is_dataset: true).order( :name, :id ) }, class_name: 'Report'
  has_many :true_reports, -> { where(is_dataset: false).order( :name, :id ) }, class_name: 'Report'

  # has_many :query_users, dependent: :destroy
  # has_many :users, through: :query_users, order: 'last_name, first_name', conditions: ['users.deleted = ?', false]

  # Search Methods

  def generate_resolvers(current_user, source, temp_criteria = self.criteria)
    temp_criteria.collect{|qc| Resolver.new(qc, source, current_user)}
  end

  def file_type_count(current_user, file_type)
    source_files = {}
    selected_report_concepts = []
    Variable.current.with_source(self.sources.collect{|s| s.id}).where( variable_type: 'file' ).each do |variable|
      selected_report_concepts << ReportConcept.new( variable_id: variable.id )
    end
    self.sources.with_file_type(file_type.id).each do |source|
      source_files[source.id] = {}
      values = self.view_concept_values(current_user, selected_report_concepts, ["download files"])

      all_files = {}
      selected_report_concepts.each_with_index do |report_concept, concept_index|
        values.each do |value|
          all_files[report_concept.variable.id] = [] if all_files[report_concept.variable.id].blank?
          all_files[report_concept.variable.id] << value[concept_index]
        end
      end

      all_files.each do |variable_id, file_locators|
        source_files[source.id][variable_id] = Aqueduct::Builder.repository(source, current_user).count_files(file_locators, file_type.extension) if Concept.with_source(source.id).find_by_id(variable_id)
      end
    end

    source_files
  end

  def available_files(current_user)
    selected_report_concepts = []
    Variable.current.with_source(self.sources.collect{|s| s.id}).where( variable_type: 'file' ).each do |variable|
      selected_report_concepts << ReportConcept.new( variable_id: variable.id )
    end

    values = self.view_concept_values(current_user, selected_report_concepts)
    all_files = {}
    selected_report_concepts.each_with_index do |report_concept, concept_index|
      values.each do |value|
        all_files[report_concept.variable.id] = [] if all_files[report_concept.variable.id].blank?
        all_files[report_concept.variable.id] << value[concept_index]
      end
    end

    all_files
  end

  def record_count_only_with_sub_totals_using_resolvers(current_user, source, temp_criteria = self.criteria)
    resolvers = generate_resolvers(current_user, source, temp_criteria)

    master_sql_statement = ''
    master_counts = []
    master_selects = resolvers.collect(&:selects).flatten.compact.uniq{ |hash| hash[:variable] }
    Rails.logger.debug master_selects
    master_tables = resolvers.collect(&:tables).flatten.compact.uniq
    join_hash = source.join_conditions(master_tables, current_user)
    resolver_conditions = resolvers.collect(&:conditions_for_entire_search).join(' ')
    master_conditions = [join_hash[:result], resolver_conditions].select{|c| not c.blank?}.join(' and ')

    Rails.logger.debug "MASTER TABLES:"
    Rails.logger.debug master_tables
    Rails.logger.debug "MASTER SELECTS:"
    Rails.logger.debug master_selects

    if master_tables.size > 0 and master_selects.size > 0
      wrapper = Aqueduct::Builder.wrapper(source, current_user)
      master_sql_statement = "SELECT #{master_selects.collect{|star| "COUNT(#{star[:table_column]})"}.join(', ')} FROM #{master_tables.join(', ')} WHERE #{master_conditions}"

      wrapper.connect
      (results, number_of_rows) = wrapper.query(master_sql_statement)
      wrapper.disconnect

      results.to_a.first.each_with_index do |count, index|
        master_counts << { count: count, variable: master_selects[index][:variable] }
      end
    end


    sub_totals = resolvers.collect{|r| ["record_ids_#{r.position}", r.counts]} + [[nil, master_counts]]
    sql_conditions = resolvers.collect(&:sql_conditions) + [master_sql_statement]
    errors = resolvers.collect{|r| ["record_ids_#{r.position}", r.errors.join(',')]}

    Rails.logger.debug "SUBTOTALS"
    Rails.logger.debug sub_totals

    { result: sub_totals, errors: errors, sql_conditions: sql_conditions }
  end

  def view_concept_values(current_user, selected_report_concepts, actions_required = ["view data distribution", "view limited data distribution"])
    MasterResolver.new(selected_report_concepts, self, current_user, actions_required).values

    # result = []
    # selected_sources.select!{|source| source.user_has_one_or_more_actions?(current_user, actions_required)}.each do |source|
    #   result += MasterResolver.new(selected_report_concepts, self, current_user, source, actions_required).values
    # end

    # return result
  end

  def reorder(criterium_ids)
    return if (criterium_ids | self.criteria.collect{|qc| qc.id.to_s}).size != self.criteria.size or criterium_ids.size != self.criteria.size

    criterium_ids.each_with_index do |criterium_id, index|
      self.criteria.find_by_id(criterium_id).update_attributes position: index
    end

    self.reload
    self.update_brackets!
  end

  def update_brackets!
    current_level = 0
    current_offset = 0
    previous_criterium = nil
    previous_operator = self.criteria.first ? self.criteria.first.right_operator : nil
    self.criteria.each do |criterium|
      if previous_criterium and previous_criterium.level != criterium.level
        current_offset = 0
      end
      # unless previous_criterium and previous_criterium.level == criterium.level and previous_criterium.level > 0 and current_offset == 1
      #   current_offset = 0
      # end

      previous_criterium.update_column :right_brackets, [current_level - criterium.level + current_offset, 0].max if previous_criterium
      criterium.update_column :left_brackets, [criterium.level - current_level + current_offset, 0].max
      if previous_criterium and previous_operator != criterium.right_operator and previous_criterium.level == criterium.level and criterium.level > 0 and current_offset == 0
        current_offset = 1
      else
        current_offset = 0
      end
      current_level = criterium.level
      previous_criterium = criterium
      previous_operator = criterium.right_operator
    end

    previous_criterium.update_column :right_brackets, [current_level, 0].max if previous_criterium
    self.reload
  end

  def update_positions
    self.criteria.each_with_index{ |qc, index| qc.update_column :position, index }
    self.reload
  end

  # Returns whether the search has an action to undo
  def undo?
    self.history_position > 0
  end

  # Returns whether the search has an action to redo
  def redo?
    self.history_position < self.history.size
  end

  def undo!
    self.directional_do!(-1, 0)
  end

  def redo!
    self.directional_do!(0, 1)
  end

  def directional_do!(position, direction)
    current_position = self.history_position + position
    if current_position >= 0 and current_position < self.history.size
      history_hash = self.history[current_position].symbolize_keys
      qc = Criterium.find_by_id(history_hash[:id])
      case history_hash[:action] when 'create'
        if direction == 0 then qc.destroy else qc.undestroy end
      when 'destroy'
        if direction == 0 then qc.undestroy else qc.destroy end
      when 'update'
        if direction == 0
          down_changes = {}
          history_hash[:changes].each_pair do |key, val|
            down_changes[key] = val.first
          end
          qc.update_attributes down_changes
        else
          up_changes = {}
          history_hash[:changes].each_pair do |key, val|
            up_changes[key] = val.last
          end
          qc.update_attributes up_changes
        end
      end
      self.update_attributes history_position: current_position + direction # Needs to trigger the save
      self.update_positions
      self.reload
      self.update_brackets!
    end
  end

  # If the undo is in the middle of the stack, add the forward redo actions to the top of the stack and point to the last item
  def roll_forward_search_history!
    max = self.history.size - 1
    (self.history_position..max).reverse_each do |current_position|
      history_hash = self.history[current_position].symbolize_keys
      case history_hash[:action] when 'create'
        self.history << { action: 'destroy', id: history_hash[:id] }
      when 'destroy'
        self.history << { action: 'create', id: history_hash[:id] }
      when 'update'
        new_changes = {}
        history_hash[:changes].each_pair do |key, val|
          new_changes[key] = [val.last, val.first]
        end
        self.history << { action: 'update', id: history_hash[:id], changes: new_changes }
      end
    end
    self.history_position = self.history.size
    self.save!
    self.reload
    self.update_brackets!
  end

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'user_id', 'deleted', 'created_at', 'updated_at'].include?(key.to_s)}
  end

  def copy
    search_copy = self.user.searches.new(self.copyable_attributes)
    search_copy.name += " Copy"
    search_copy.save
    self.query_sources.each do |qs|
      search_copy.sources << qs.source
    end
    self.criteria.each do |qc|
      search_copy.criteria << search_copy.criteria.create(qc.copyable_attributes)
    end
    search_copy.history = []
    search_copy.history_position = 0
    search_copy.save
    search_copy
  end
end
