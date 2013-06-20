class Source < ActiveRecord::Base

  WRAPPER = Aqueduct.wrappers.collect{|a| [a.to_s.split('::').last, a.to_s.split('::').last.downcase]}
  REPOSITORY = Aqueduct.repositories.collect{|a| [a.to_s.split('::').last, a.to_s.split('::').last.downcase]}

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :available, -> { where deleted: false, visible: true }
  scope :available_or_creator_id, lambda { |arg| where( [ "sources.deleted = ? and (sources.visible = ? or sources.user_id IN (?))", false, true, arg ] ) }
  scope :local, -> { where identifier: nil }
  scope :with_concept, lambda { |arg|  where( ["sources.id in (select source_id from mappings where mappings.concept_id IN (?) and mappings.status IN (?) and mappings.deleted = ?) or '' IN (?)", arg, ['mapped', 'unmapped', 'derived'], false, arg] ) }
  scope :with_file_type, lambda { |arg| where( ["sources.id IN (select source_id from source_file_types where source_file_types.file_type_id IN (?))", arg] ) }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  # Model Relationships
  belongs_to :user
  has_many :mappings, -> { where deleted: false }
  has_many :concepts, -> { order :short_name }, through: :mappings

  has_many :source_joins, dependent: :destroy
  has_many :reverse_source_joins, class_name: 'SourceJoin', foreign_key: 'source_to_id', dependent: :destroy

  has_many :sources, through: :source_joins, source: 'source_to'
  has_many :rev_sources, through: :reverse_source_joins, source: 'source'

  has_many :source_file_types, dependent: :destroy
  has_many :file_types, -> { order :name }, through: :source_file_types

  has_many :source_rules, dependent: :destroy

  # has_many :database_access_rules, dependent: :destroy
  has_many :query_sources, dependent: :destroy
  has_many :queries, -> { order :name }, through: :query_sources

  # Source Methods

  def all_dictionaries
    Dictionary.available.find(self.concepts.select(:dictionary_id).group(:dictionary_id).collect(&:dictionary_id).uniq)
  end

  def all_source_joins
    self.source_joins | self.reverse_source_joins
  end

  def all_linked_sources(concept_id = nil)
    (self.sources.with_concept(concept_id || '') | self.rev_sources(concept_id || '')) - [self]
  end

  def all_linked_sources_and_self(concept_id = nil)
    self.all_linked_sources(concept_id) + [self]
  end

  def local_source_joins
    self.source_joins.where(["source_to_id = ? or source_to_id IS NULL", self.id])
  end

  def file_server_available?(current_user)
    Aqueduct::Builder.repository(self, current_user).file_server_available?
  end

  def use_sql?(current_user)
    Aqueduct::Builder.wrapper(self, current_user).use_sql?
  end

  def sql_codes(current_user)
    Aqueduct::Builder.wrapper(self, current_user).sql_codes
  end

  def tables(current_user)
    Aqueduct::Builder.wrapper(self, current_user).tables
  end

  def table_columns(current_user, table, page = 1, per_page = -1, filter_unmapped = false)
    result_hash = Aqueduct::Builder.wrapper(self, current_user).table_columns(table)

    columns = result_hash[:columns]
    error = result_hash[:error]

    if filter_unmapped
      mapped_columns = self.mappings.where(status: 'mapped', table: table).pluck(:column)
      unmapped_columns = self.mappings.where(status: 'unmapped', table: table).pluck(:column)
      filtered_columns = []
      columns.each do |column_hash|
        if unmapped_columns.include?(column_hash[:column]) or not mapped_columns.include?(column_hash[:column])
          filtered_columns << column_hash
        end
      end
      columns = filtered_columns
    end

    if per_page > 0
      max_pages = (columns.size / per_page) + 1
      page = max_pages if page > max_pages
      { result: columns.sort{|a,b| a[:column].to_s.downcase <=> b[:column].to_s.downcase}[((page-1)*per_page)..(page*per_page-1)], max_pages: max_pages, page: page, error: error }
    else
      { result: columns.sort{|a,b| a[:column].to_s.downcase <=> b[:column].to_s.downcase}, error: error }
    end
  end

  def has_repository?(current_user)
    result_hash = Aqueduct::Builder.repository(self, current_user).has_repository?
    return result_hash[:result]
  end

  def human_repository
    repositories = Source::REPOSITORY.select{|a| a[1] == self.repository}
    if repositories.size > 0
      repositories.first.first
    else
      ''
    end
  end

  def human_wrapper
    wrappers = Source::WRAPPER.select{|a| a[1] == self.wrapper}
    if wrappers.size > 0
      wrappers.first.first
    else
      ''
    end
  end

  # Check if the user has at least one action in the given action_group
  def user_has_action_group?(current_user, action_group)
    SourceRule.action_group_items(action_group).each do |action|
      return true if self.user_has_action?(current_user, action)
    end
    return false
  end

  def user_has_action?(current_user, action)
    return true if current_user.all_sources.include?(self)
    result = false
    blocked = false
    self.source_rules.each do |rule|
      if rule.user_has_action?(current_user, action)
        if rule.blocked?
          blocked = true
        else
          result = true
        end
      end
    end
    result = false if blocked
    result
  end

  # Check if the user has at least one of the actions
  def user_has_one_or_more_actions?(current_user, actions = [])
    actions.each do |action|
      return true if self.user_has_action?(current_user, action)
    end
    return false
  end

  # Returns tables for a selected concepts
  def concept_tables(concept)
    result = []
    if concept
      mappings = self.mappings.where(concept_id: concept.id).where(['mappings.status IN (?)', ['mapped', 'unmapped', 'derived']])
      result = mappings.collect{|m| m.table}.uniq
    end
    result
  end

  # This is for NON-SQL wrappers, make the wrapper itself generate the concept tables
  def concept_tables_external_wrap(current_user, query_concept)
    Aqueduct::Builder.wrapper(self, current_user).concept_tables(query_concept)
  end

  def conditions_external_wrap(current_user, query_concepts)
    Aqueduct::Builder.wrapper(self, current_user).conditions(query_concepts)
  end

  # Given a list of tables find all the join conditions
  def join_conditions(tables, current_user)
    result = []
    errors = []
    tables.each_with_index do |table_one, table_index|
      for i in (table_index+1..tables.size-1)
        table_two = tables[i]
        # find Join Condition if it exists between table_one and table_two
        join = self.local_source_joins.find_by_from_table_and_to_table(table_one, table_two)
        join = self.local_source_joins.find_by_from_table_and_to_table(table_two, table_one) unless join

        result_hash = self.sql_codes(current_user)
        sql_open = result_hash[:open]
        sql_close = result_hash[:close]

        if join
          result << "#{join.from_table}.#{sql_open}#{join.from_column}#{sql_close} = #{join.to_table}.#{sql_open}#{join.to_column}#{sql_close}"
        else
          errors << "No Table join found between tables #{table_one} and #{table_two}"
        end
      end
    end
    { result: result, errors: errors }
  end

  def derived_concepts
    @derived_concepts ||= begin
      self.concepts.where(['mappings.status IN (?)', ['mapped', 'unmapped', 'derived']])
    end
  end

  def linked_concepts
    Concept.with_source(self.all_linked_sources)
  end

  def count(current_user, query_concepts, conditions, tables, join_conditions, select_identifier_concept)
    Aqueduct::Builder.wrapper(self, current_user).count(query_concepts, conditions, tables, join_conditions, select_identifier_concept ? select_identifier_concept.mapped_name(current_user, self) : nil)
  end

  def table_columns_mapped(current_user, table)
    result_hash = self.table_columns(current_user, table)
    columns = result_hash[:result].collect{|c| c[:column]}
    number_mapped = self.mappings.where( table: table, status: 'mapped', column: columns ).uniq.select(:column).count
    "#{number_mapped} of #{columns.size}"
  end

  # This function calculates the derived mappings for a database.
  # Expensive Operation
  def generate_derived_mappings!
    self.mappings.status('derived').destroy_all()
    self.mappings.status(['mapped', 'unmapped']).each{|m| m.generate_derived!}
  end

  def external_concepts(current_user, folder = '', search_term = '')
    Aqueduct::Builder.wrapper(self, current_user).external_concepts(folder, search_term)
  end

  def external_concept_information(current_user, external_key)
    Aqueduct::Builder.wrapper(self, current_user).external_concept_information(external_key)
  end

  def get_values_for_concepts(current_user, conditions, tables, view_concept_ids, actions_required = ['view data distribution', 'view limited data distribution'])
    result = []
    result2 = {}
    error = ''

    wrapper = Aqueduct::Builder.wrapper(self, current_user)

    if wrapper.use_sql?
      begin
        mappings_for_select_clause = []
        self.mappings.where(concept_id: view_concept_ids).each do |mapping|
          mappings_for_select_clause << mapping if mapping.user_can_view?(current_user, actions_required)
        end

        tables_covered_by_concepts = (mappings_for_select_clause.collect{|m| m.table} | tables).uniq
        join_conditions_hash = self.join_conditions(tables_covered_by_concepts, current_user)
        error = join_conditions_hash[:errors].join(', ')

        if mappings_for_select_clause.size > 0 and tables_covered_by_concepts.size > 0

          result_hash = wrapper.sql_codes
          sql_open = result_hash[:open]
          sql_close = result_hash[:close]

          sql_statement = "SELECT #{mappings_for_select_clause.collect{|m| m.table + '.' + sql_open + m.column + sql_close}.join(',')} FROM #{tables_covered_by_concepts.join(', ')} WHERE #{join_conditions_hash[:result].join(' and ')}#{' and ' unless join_conditions_hash[:result].blank?}#{conditions}"

          logger.debug "\n\nSQL for #{self.name}:\n\n   #{sql_statement}\n\n"

          t = Time.now

          concept_cnames = mappings_for_select_clause.each_with_index.collect{|m,i| m.concept ? m.concept.cname : "tmp_#{i}"}

          wrapper.connect
          (results, number_of_rows) = wrapper.query(sql_statement)
          wrapper.disconnect


          result = Array.new(number_of_rows + 1) {Array.new(concept_cnames.size)}

          # result << concept_cnames # mappings_for_select_clause.collect{|dc| dc.concept ? dc.concept.cname : 'blank_concept'}
          result[0] = concept_cnames

          # mappings_for_select_clause.each {|dc| datatypes[dc.concept.cname] = dc.concept.data_type if dc.concept}

          t3 = Time.now

          index_of_cname = {}
          mappings_for_select_clause.each_with_index do |mapping, m_index|
            index_of_cname[mapping.concept ? mapping.concept.cname : "tmp_#{m_index}"] = m_index
          end

          massive_result_array = []
          results.each{|row| massive_result_array << row }
          results = nil

          concept_cnames.each_with_index do |cname, column_index|
            mapping = mappings_for_select_clause.select{|m| (m.concept ? m.concept.cname : "tmp_#{column_index}") == cname}.first
            dccv_conversions = {}
            if mapping
              # TODO: Replace this with or something similar... see Mapping::human_normalized_value(val) and Mapping::uniq_normalized_value(val)
              #   dccv_conversions['val_'+val_mapping.column_value.to_s] = mapping.human_normalized_value(val)

              val_mappings = self.mappings.where(["mappings.table = ? and mappings.column = ? and mappings.column_value IS NOT NULL and mappings.status IN (?)", mapping.table, mapping.column, ['mapped']])
              val_mappings.each do |val_mapping|
                if mapping.concept.boolean? and val_mapping.value.blank?
                  dccv_conversions['val_'+val_mapping.column_value.to_s] = (val_mapping.concept == mapping.concept) ? 'true' : 'false'
                elsif mapping.concept.boolean? or not val_mapping.value.blank?
                  dccv_conversions['val_'+val_mapping.column_value.to_s] = val_mapping.value
                else
                  dccv_conversions['val_'+val_mapping.column_value.to_s] = val_mapping.concept.human_name
                end
              end
            end

            cname_index = index_of_cname[cname]
            if not cname_index.blank? or cname == 'source_id'
              (1..massive_result_array.size).each do |row_index|
                if cname == 'source_id'
                  result[row_index][column_index] = self.id
                  result2[cname] = [] if result2[cname].blank?
                  result2[cname] << self.id
                else
                  if massive_result_array[row_index-1][cname_index].class != String and massive_result_array[row_index-1][cname_index].respond_to?('round') and massive_result_array[row_index-1][cname_index].round == massive_result_array[row_index-1][cname_index]
                    massive_result_array[row_index-1][cname_index] = massive_result_array[row_index-1][cname_index].round
                  end

                  mra = 'val_' + ( (massive_result_array[row_index-1][cname_index] == nil) ? 'NULL' : massive_result_array[row_index-1][cname_index].to_s )

                  if dccv_conversions[mra].blank?
                    result[row_index][column_index] = massive_result_array[row_index-1][cname_index]
                    result2[cname] = [] if result2[cname].blank?
                    result2[cname] << massive_result_array[row_index-1][cname_index]
                  else
                    result[row_index][column_index] = dccv_conversions[mra]
                    result2[cname] = [] if result2[cname].blank?
                    result2[cname] << dccv_conversions[mra]
                  end
                end
              end
            else
              logger.debug "Skipping #{cname}"
            end
          end
          logger.debug "Took #{Time.now - t3} seconds to retrieve t3."
        elsif mappings_for_select_clause.size == 0
          error = "Source #{self.name}: The selected concept is not mapped."
        elsif tables_covered_by_concepts.size == 0
          error = "Source #{self.name}: No tables specified in FROM clause."
        end
      rescue => e
        error = "Source [#{self.name}] Error: #{e.inspect}"
        logger.debug error
      ensure
        wrapper.disconnect
      end
    elsif not wrapper.use_sql?
      begin
        wrapper.connect
        (result, number_of_rows) = wrapper.query(conditions)
      rescue => e
        error = "Source [#{self.name}] Error: #{e.inspect}"
        logger.debug error
      ensure
        wrapper.disconnect
      end
    else
      error = "Unknown Wrapper: [#{self.wrapper}]"
    end
    { result: result, error: error }
    # {result: result2, error: error}
  end
end
