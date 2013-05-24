class Query < ActiveRecord::Base
  serialize :history, Array

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :with_user, lambda { |arg| where( ["queries.user_id = ? or queries.id in (select query_users.query_id from query_users where query_users.user_id = ?)", arg, arg] ) }

  # Model Validation
  validates_presence_of :name

  # Model Relationships
  belongs_to :user
  belongs_to :identifier_concept, class_name: "Concept"

  has_many :query_concepts, -> { where(deleted: false).order('position') }
  has_many :concepts, -> { order :position }, through: :query_concepts

  has_many :query_sources, dependent: :destroy
  has_many :sources, -> { order :name }, through: :query_sources

  has_many :reports

  has_many :true_datasets, -> { where(is_dataset: true).order('(reports.name IS NULL or reports.name = ""), reports.name, reports.id') }, class_name: "Report"
  has_many :true_reports, -> { where(is_dataset: false).order('(reports.name IS NULL or reports.name = ""), reports.name, reports.id') }, class_name: "Report"

  # has_many :query_users, dependent: :destroy
  # has_many :users, through: :query_users, order: 'last_name, first_name', conditions: ['users.deleted = ?', false]

  # Query Methods

  def generate_resolvers(current_user, source, temp_query_concepts = self.query_concepts)
    temp_query_concepts.collect{|qc| Resolver.new(qc, source, current_user)}
  end

  def file_type_count(current_user, file_type)
    source_files = {}
    concepts = Concept.current.searchable.with_source(self.sources.collect{|s| s.id}).with_concept_type('file locator')
    self.sources.with_file_type(file_type.id).each do |source|
      source_files[source.id] = {}
      result_hash = self.view_concept_values(current_user, self.sources, concepts.collect{|c| c.id}, self.query_concepts, [], ["download files"])
      all_files = {}
      if result_hash[:error].blank?
        values = result_hash[:result][1..-1]
        concepts.each_with_index do |concept, concept_index|
          values.each do |value|
            all_files[concept.id] = [] if all_files[concept.id].blank?
            all_files[concept.id] << value[concept_index]
          end
        end
      end

      all_files.each do |concept_id, file_locators|
        source_files[source.id][concept_id] = Aqueduct::Builder.repository(source, current_user).count_files(file_locators, file_type.extension) if Concept.with_source(source.id).find_by_id(concept_id)
      end
    end

    source_files
  end

  def available_files(current_user)
    concepts = Concept.current.searchable.with_source(self.sources.collect{|s| s.id}).with_concept_type('file locator')

    result_hash = self.view_concept_values(current_user, self.sources, concepts.collect{|c| c.id})
    all_files = {}
    if result_hash[:error].blank?
      values = result_hash[:result][1..-1]
      concepts.each_with_index do |concept, concept_index|
        values.each do |value|
          all_files[concept.id] = [] if all_files[concept.id].blank?
          all_files[concept.id] << value[concept_index]
        end
      end
    end

    all_files
  end


  # Builds the conditions and subconditions given a query with query_concepts, or temporary_concepts from the Query Builder
  def build_conditions(current_user, source, temp_query_concepts = self.query_concepts)
    t_start = Time.now
    return {result: [[nil, '']], errors: []} if temp_query_concepts.blank?

    sub_conditions = []
    errors = []
    overall_errors = []
    overall_error_found = false

    # Invididual Row Conditions
    temp_query_concepts.each do |query_concept|
      tables = []
      join_conditions = ''
      concept = query_concept.concept

      # Determine what tables need to be used and join_conditions
      if source.use_sql?(current_user)
        tables << source.concept_tables(query_concept.concept)
        tables.flatten!
        tables.uniq!
        join_conditions_hash = source.join_conditions(tables, current_user)
        errors += join_conditions_hash[:errors] unless join_conditions_hash[:errors].blank?
        join_conditions = join_conditions_hash[:result]
      else
        result_table_hash = source.concept_tables_external_wrap(current_user, query_concept)
        errors += result_table_hash[:error] unless result_table_hash[:error].blank?
        tables << result_table_hash[:result]
      end

      # TODO: Figure out what this does...(compared to the tables that are created above)
      if source.use_sql?(current_user)
        result_hash = query_concept.construct_sql(current_user, source)
        tables += result_hash[:tables]

        if concept and (source.derived_concepts.include?(concept) or source.linked_concepts.where(["concepts.id = ?", concept.id]).size > 0)

          unless result_hash[:error].blank?
            # overall_error_found = true
            errors << ["record_ids_#{query_concept.id}", result_hash[:error]]
            # overall_errors << result_hash[:error]
          end

          sub_conditions << {position: "record_ids_#{query_concept.id}", conditions: result_hash[:conditions], tables: tables, join_conditions: join_conditions}


        elsif concept
          overall_error_found = true
          errors << ["record_ids_#{query_concept.id}", "Concept #{query_concept.concept.human_name} Not Mapped in #{source.name}"]
          overall_errors << "Concept #{query_concept.concept.human_name} Not Mapped in #{source.name}"
          sub_conditions << {position: "record_ids_#{query_concept.id}", conditions: result_hash, tables: tables, join_conditions: join_conditions}
        end
      else
        # Subconditions generation for SQLless wrappers
        result_hash = source.conditions_external_wrap(current_user, [query_concept])
        errors << ["record_ids_#{query_concept.id}", result_hash[:error]] unless result_hash[:error].blank?
        sub_conditions << {position: "record_ids_#{query_concept.id}", conditions: result_hash[:conditions], tables: tables, join_conditions: join_conditions}
      end
    end

    select_tables = [] # TODO: Remove select_tables as it doesn't seem needed
    all_conditions = []

    temp_query_concepts.each do |qc|
      result_hash = qc.construct_sql_wrap(current_user, source, temp_query_concepts)
      select_tables += result_hash[:tables]
      all_conditions << result_hash[:conditions]
    end

    conditions = all_conditions.join(' ')
    conditions = "#{'NOT ' if self.negated?}(" + conditions + ')' if source.use_sql?(current_user)

    overall_tables = []
    overall_join_conditions = []

    # Determine what tables need to be used and join_conditions
    if source.use_sql?(current_user)
      overall_tables = Array.new(select_tables) # TODO: Remove select_tables as it doesn't seem needed
      temp_query_concepts.each do |query_concept|
        overall_tables << source.concept_tables(query_concept.concept)
        overall_tables.flatten!
      end
      overall_tables.uniq!
      overall_join_conditions_hash = source.join_conditions(overall_tables, current_user)
      overall_errors += overall_join_conditions_hash[:errors] unless overall_join_conditions_hash[:errors].blank?
      overall_errors.uniq!
      overall_join_conditions = overall_join_conditions_hash[:result]
    else
      overall_tables = Array.new(select_tables) # TODO: Remove select_tables as it doesn't seem needed
      temp_query_concepts.each do |query_concept|
        result_table_hash = source.concept_tables_external_wrap(current_user, query_concept)
        overall_tables << result_table_hash[:result]
        overall_tables.flatten!
      end
      overall_tables.uniq!
      result_hash = source.conditions_external_wrap(current_user, temp_query_concepts)
      conditions = result_hash[:conditions]
      errors << result_hash[:error] unless result_hash[:error].blank?
    end

    sub_conditions << {position: nil, conditions: conditions, tables: overall_tables, join_conditions: overall_join_conditions}
    errors << [nil, "Not All Concepts Are Mapped in #{source.name}: #{overall_errors.join(', ')}"] if overall_error_found

    return { result: sub_conditions, errors: errors }
  end

  def record_count_only_with_sub_totals_using_resolvers(current_user, source, temp_query_concepts = self.query_concepts)
    return { result: [[nil, 0]], errors: [] } if temp_query_concepts.blank?

    resolvers = generate_resolvers(current_user, source, temp_query_concepts)

    master_total = 0
    master_tables = resolvers.collect(&:tables).flatten.compact.uniq
    join_hash = source.join_conditions(master_tables, current_user)
    resolver_conditions = resolvers.collect(&:conditions_for_entire_query).join(' ')
    master_conditions = [join_hash[:result], resolver_conditions].select{|c| not c.blank?}.join(' and ')

    if master_tables.size > 0 and source.use_sql?(current_user)
      wrapper = Aqueduct::Builder.wrapper(source, current_user)
      sql_statement = "SELECT COUNT(*) FROM #{master_tables.join(', ')} WHERE #{master_conditions}"
      wrapper.connect
      (results, number_of_rows) = wrapper.query(sql_statement)
      wrapper.disconnect
      master_total = results.to_a.first[0]
    end


    sub_totals = resolvers.collect{|r| ["record_ids_#{r.position}", r.count]} + [[nil, master_total]]
    sql_conditions = resolvers.collect{|r| r.tables.join(',') + ' WHERE ' + r.conditions} + [master_tables.join(',') + ' WHERE ' + master_conditions]
    errors = resolvers.collect{|r| ["record_ids_#{r.position}", r.errors.join(',')]}

    return { result: sub_totals, errors: errors, sql_conditions: sql_conditions }
  end

  def record_count_only_with_sub_totals(current_user, source, temp_query_concepts = self.query_concepts)
    return { result: [[nil, 0]], errors: [] } if temp_query_concepts.blank?

    build_conditions_hash = self.build_conditions(current_user, source, temp_query_concepts)

    sub_totals = []
    sub_conditions = build_conditions_hash[:result]
    errors = build_conditions_hash[:errors]

    sql_conditions = ''

    # Iterate through sub_conditions and retrieve count.  The sub_condition with a [nil, conditions] is the overall query.
    sub_conditions.each do |sub_condition|
      result_hash = source.count(current_user, temp_query_concepts, sub_condition[:conditions], sub_condition[:tables], sub_condition[:join_conditions], self.identifier_concept)
      sql_conditions = result_hash[:sql_conditions] if sub_condition[:position] == nil

      sub_totals << [sub_condition[:position], result_hash[:result]]
      errors << [sub_condition[:position], result_hash[:error]] unless result_hash[:error].blank?
    end

    return { result: sub_totals, errors: errors, sql_conditions: sql_conditions }
  end

  def view_concept_values(current_user, selected_sources, view_concept_ids, temp_query_concepts = self.query_concepts, table_columns = [], actions_required = ["view data distribution", "view limited data distribution"])
    result = [[]]
    error = ''
    return { result: result, error: error } if temp_query_concepts.blank?

    available_sources = []
    selected_sources.each do |source|
      if source.user_has_one_or_more_actions?(current_user, actions_required)
        available_sources << source
      end
    end

    result[0] = view_concept_ids.collect{|c_id| (c = Concept.find_by_id(c_id)) ? c.cname : nil}

    available_sources.each do |source|
      conditions_hash = self.build_conditions(current_user, source, temp_query_concepts)
      if conditions_hash[:error].blank?
        overall_build_conditions = conditions_hash[:result].select{|bc| bc[:position] == nil}.first
        result_hash = source.get_values_for_concepts(current_user, overall_build_conditions[:conditions], overall_build_conditions[:tables], conditions_hash[:select_identifier_concept], view_concept_ids, table_columns, actions_required)
        if result_hash[:error].blank?
          # Combine new hash with previous results from other sources
          # TODO: This line may no longer be needed as the initial view_concept_ids should cover all concepts that are retrieved.
          result[0] = (result.first + result_hash[:result].first).uniq

          result_hash[:result][1..-1].each do |row|
            result_row = []
            result_hash[:result].first.each_with_index do |cname, column_index|
              result_row[result.first.index(cname)] = row[column_index]
            end
            result << result_row
          end
        else
          error = result_hash[:error]
        end
      else
        error = condition_hash[:error]
      end
    end

    error = "You do not have #{actions_required.collect{|a| '<span class="source_rule_text">'+a+'</span>'}.join(' or ')} in any of you selected data sources: <ul>#{selected_sources.collect{|s| "<li><b><i>#{s.name}</i></b></li>"}.join}</ul>" if available_sources.size == 0
    return { result: result, error: error }
  end

  def reorder(query_concept_ids)
    return if (query_concept_ids | self.query_concepts.collect{|qc| qc.id.to_s}).size != self.query_concepts.size or query_concept_ids.size != self.query_concepts.size

    query_concept_ids.each_with_index do |query_concept_id, index|
      self.query_concepts.find_by_id(query_concept_id).update_attributes position: index
    end

    self.reload
    self.update_brackets!
  end

  def update_brackets!
    current_level = 0
    current_offset = 0
    previous_query_concept = nil
    previous_operator = self.query_concepts.first ? self.query_concepts.first.right_operator : nil
    self.query_concepts.each do |query_concept|
      if previous_query_concept and previous_query_concept.level != query_concept.level
        current_offset = 0
      end
      # unless previous_query_concept and previous_query_concept.level == query_concept.level and previous_query_concept.level > 0 and current_offset == 1
      #   current_offset = 0
      # end

      previous_query_concept.update_column :right_brackets, [current_level - query_concept.level + current_offset, 0].max if previous_query_concept
      query_concept.update_column :left_brackets, [query_concept.level - current_level + current_offset, 0].max
      if previous_query_concept and previous_operator != query_concept.right_operator and previous_query_concept.level == query_concept.level and query_concept.level > 0 and current_offset == 0
        current_offset = 1
      else
        current_offset = 0
      end
      current_level = query_concept.level
      previous_query_concept = query_concept
      previous_operator = query_concept.right_operator
    end

    previous_query_concept.update_column :right_brackets, [current_level, 0].max if previous_query_concept
    self.reload
  end

  def update_positions
    self.query_concepts.each_with_index{ |qc, index| qc.update_column :position, index }
    self.reload
  end

  # Returns whether the query has an action to undo
  def undo?
    self.history_position > 0
  end

  # Returns whether the query has an action to redo
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
      qc = QueryConcept.find_by_id(history_hash[:id])
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
  def roll_forward_query_history!
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
    query_copy = self.user.queries.new(self.copyable_attributes)
    query_copy.name += " Copy"
    query_copy.save
    self.query_sources.each do |qs|
      query_copy.sources << qs.source
    end
    self.query_concepts.each do |qc|
      query_copy.query_concepts << query_copy.query_concepts.create(qc.copyable_attributes)
    end
    query_copy.history = []
    query_copy.history_position = 0
    query_copy.save
    query_copy
  end
end
