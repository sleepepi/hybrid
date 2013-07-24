class Source < ActiveRecord::Base

  WRAPPER = Aqueduct.wrappers.collect{|a| [a.to_s.split('::').last, a.to_s.split('::').last.downcase]}
  REPOSITORY = Aqueduct.repositories.collect{|a| [a.to_s.split('::').last, a.to_s.split('::').last.downcase]}

  serialize :table_hash, Hash

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :available, -> { where deleted: false, visible: true }
  scope :available_or_creator_id, lambda { |arg| where( [ "sources.deleted = ? and (sources.visible = ? or sources.user_id IN (?))", false, true, arg ] ) }
  scope :local, -> { where identifier: nil }
  # scope :with_concept, lambda { |arg|  where( ["sources.id in (select source_id from mappings where mappings.concept_id IN (?)) or '' IN (?)", arg, arg] ) }
  scope :with_variable, lambda { |arg|  where( ["sources.id in (select source_id from mappings where mappings.variable_id IN (?))", arg] ) }
  scope :with_file_type, lambda { |arg| where( ["sources.id IN (select source_id from source_file_types where source_file_types.file_type_id IN (?))", arg] ) }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  # Model Relationships
  belongs_to :user
  has_many :mappings
  # has_many :concepts, -> { order :short_name }, through: :mappings
  has_many :variables, -> { order :display_name }, through: :mappings

  has_many :source_file_types, dependent: :destroy
  has_many :file_types, -> { order :name }, through: :source_file_types

  has_many :rules, dependent: :destroy

  has_many :query_sources, dependent: :destroy
  has_many :searches, -> { order :name }, through: :query_sources

  # Source Methods

  # Returns the dictionary associated with the most mappings
  def primary_dictionary
    dictionary_ids = Variable.where(id: self.mappings.pluck(:variable_id).uniq).pluck(:dictionary_id)
    frequency = dictionary_ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
    Dictionary.available.find_by_id(dictionary_ids.sort_by { |v| frequency[v] }.last)
  end

  def all_dictionaries
    Dictionary.available.where( id: self.variables.select(:dictionary_id).group(:dictionary_id, :display_name).collect(&:dictionary_id).uniq )
  end

  def all_linked_sources
    identifiers = self.variables.where( variable_type: 'identifier' ).pluck(:id)
    if identifiers.size > 0
      Source.available.where( "id != ?", self.id ).with_variable(identifiers)
    else
      Source.none
    end
  end

  def all_linked_sources_and_self
    self.all_linked_sources + [self]
  end

  def file_server_available?(current_user)
    Aqueduct::Builder.repository(self, current_user).file_server_available?
  end

  def sql_codes(current_user)
    Aqueduct::Builder.wrapper(self, current_user).sql_codes
  end

  def tables(current_user)
    Aqueduct::Builder.wrapper(self, current_user).tables
  end

  def table_columns(current_user, table, page = 1, per_page = -1, filter_unmapped = false, search = '')
    result_hash = Aqueduct::Builder.wrapper(self, current_user).table_columns(table)

    columns = result_hash[:columns]
    error = result_hash[:error]

    if filter_unmapped
      mapped_columns = self.mappings.includes(:source, :variable, { variable: :domain }).where( table: table ).select{|m| m.mapped?(current_user) }.collect{|m| m.column}.uniq
      columns.reject!{|hash| mapped_columns.include?(hash[:column])}
    end

    columns.select!{|hash| hash[:column].to_s.downcase =~ Regexp.new( search.downcase ) } unless search.blank?

    if per_page > 0
      max_pages = (columns.size / per_page) + 1
      page = max_pages if page > max_pages
      { result: columns.sort{|a,b| a[:column].to_s.downcase <=> b[:column].to_s.downcase}[((page-1)*per_page)..(page*per_page-1)], max_pages: max_pages, page: page, error: error }
    else
      { result: columns.sort{|a,b| a[:column].to_s.downcase <=> b[:column].to_s.downcase}, error: error }
    end
  end

  def has_repository?(current_user)
    return false if self.repository.blank?
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
    Rule.action_group_items(action_group).each do |action|
      return true if self.user_has_action?(current_user, action)
    end
    return false
  end

  def user_has_action?(current_user, action)
    return true if current_user.all_sources.include?(self)
    result = false
    blocked = false
    self.rules.each do |rule|
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

  def variable_tables(variable)
    self.mappings.where( variable_id: variable.id ).pluck(:table).uniq
  end

  def join_conditions(tables, current_user)
    result = []
    errors = []
    result_hash = self.sql_codes(current_user)
    sql_open = result_hash[:open]
    sql_close = result_hash[:close]

    tables.each_with_index do |table_one, table_index|
      for i in (table_index+1..tables.size-1)
        table_two = tables[i]
        # find Join Condition if it exists between table_one and table_two
        identifiers = []
        self.variables.where( variable_type: 'identifier' ).each do |variable|
          identifiers << variable if self.mappings.where( variable_id: variable.id, table: [table_one, table_two] ).uniq.pluck(:table).sort == [table_one, table_two].sort
        end

        identifier = identifiers.first

        if identifier and table_one_mapping = self.mappings.where( variable_id: identifier.id, table: table_one).first and table_two_mapping = self.mappings.where( variable_id: identifier.id, table: table_two).first
          result << "#{table_one_mapping.table}.#{sql_open}#{table_one_mapping.column}#{sql_close} = #{table_two_mapping.table}.#{sql_open}#{table_two_mapping.column}#{sql_close}"
        else
          errors << "No Table join found between tables #{table_one} and #{table_two}"
        end
      end
    end
    { result: result, errors: errors }
  end


  def count(current_user, criteria, conditions, tables, join_conditions, select_identifier_concept)
    Aqueduct::Builder.wrapper(self, current_user).count(criteria, conditions, tables, join_conditions, select_identifier_concept ? select_identifier_concept.mapped_name(current_user, self) : nil)
  end

  def table_columns_mapped(current_user, table)
    result_hash = self.table_columns(current_user, table)
    columns = result_hash[:result].collect{|c| c[:column]}
    number_mapped = self.mappings.where( table: table, column: columns ).uniq.select(:column).count
    { mapped: number_mapped, total: columns.size }
  end

end
