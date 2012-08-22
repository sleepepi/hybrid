class Concept < ActiveRecord::Base

  SENSITIVITY = [["0) Not Sensitive","0"], ["1) Requires Approval","1"], ["2) Requires Approval with Documentation","2"]]

  CONCEPT_TYPE = ['boolean', 'categorical', 'continuous', 'datetime', 'identifier', 'file locator', 'free text'].collect{|i| [i,i]}

  # Named Scopes
  scope :current, conditions: {  }  # deleted: false
  scope :searchable, lambda { |*args|  { conditions: "concepts.concept_type IS NOT NULL" } }
  scope :with_concept_type, lambda { |*args|  { conditions: ["concepts.concept_type IN (?) or 'all' IN (?)", args.first, args.first] } }

  scope :with_source, lambda { |*args|  { conditions: ["concepts.id in (select concept_id from mappings where mappings.source_id IN (?) and mappings.status IN (?) and mappings.deleted = ?)", args.first, ['mapped', 'unmapped', 'derived'], false] } } # TODO: Status of mapping no longer matters
  scope :with_folder, lambda { |*args| { conditions: ["LOWER(concepts.folder) LIKE ? or ? IS NULL", args.first.to_s + ':%', args.first] } }
  scope :with_exact_folder, lambda { |*args| { conditions: ["LOWER(concepts.folder) LIKE ? or ('Uncategorized' = ? and (concepts.folder IS NULL or concepts.folder = ''))", args.first, args.first] } }
  scope :with_exact_folder_or_subfolder, lambda { |*args| { conditions: ["LOWER(concepts.folder) LIKE ? or LOWER(concepts.folder) LIKE ? or ('Uncategorized' = ? and (concepts.folder IS NULL or concepts.folder = ''))", args.first, args.first.to_s + ':%', args.first] } }

  scope :with_dictionary, lambda { |*args| { conditions: ["concepts.dictionary_id IN (?) or 'all' IN (?)", args.first, args.first] } }
  scope :with_namespace, lambda { |*args| { conditions: ["concepts.namespace IN (?) or '' IN (?)", args.first, args.first] } }

  scope :with_report, lambda { |*args| { conditions: ["? = '' or concepts.id in (select concept_id from report_concepts where report_concepts.report_id = ?)", args.first, args.first] }}

  scope :search, lambda { |*args| {conditions: [ 'LOWER(search_name) LIKE ? or LOWER(search_name) LIKE ? or concepts.id in (select concept_id from terms where LOWER(terms.search_name) LIKE ? or LOWER(terms.search_name) LIKE ?)', args.first + '%', '% ' + args.first + '%', args.first + '%', '% ' + args.first + '%' ] } }

  scope :exactly, lambda { |*args| {conditions: [ 'LOWER(short_name) = ? or LOWER(short_name) = ? or LOWER(search_name) = ? or LOWER(search_name) = ? or concepts.id in (select concept_id from terms where LOWER(terms.search_name) = ? or LOWER(terms.search_name) = ?)', args.first, args[1], args.first, args[1], args.first, args[1] ] } }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_format_of :uri,
                      with: /^[a-zA-Z]+:\/\/[\w\-.\/]*[\w]$/,
                      message: "must be a valid URI without a trailing backslash."

  validates_format_of :namespace,
                      with: /^[\w\-.]+$/,
                      message: "must contain only digits, letters, underscores, periods, and dashes."

  validates_format_of :short_name,
                      with: /^[\w\-]+$/,
                      message: "must contain only letters, digits, underscores, and dashes."

  # Model Relationships

  has_many :mappings, dependent: :destroy
  belongs_to :dictionary
  has_many :sources, through: :mappings, order: 'sources.name', conditions: ['sources.deleted = ?', false]

  has_many :terms, order: :name, dependent: :destroy
  has_many :external_terms,  class_name: "Term", order: 'terms.name', dependent: :destroy, conditions: {internal: false}
  has_many :internal_terms,  class_name: "Term", order: 'terms.name', dependent: :destroy, conditions: {internal: true}

  has_many :concept_property_concepts, foreign_key: 'concept_one_id', order: 'property', dependent: :destroy
  has_many :parents, through: :concept_property_concepts, source: 'concept_two', conditions: 'concept_property_concepts.property = "is_a"'
  has_many :includes, through: :concept_property_concepts, source: 'concept_two', conditions: ['concept_property_concepts.property IN (?)', ["includes", "http://purl.org/cpr/includes"]]

  has_many :equivalent_concepts_a, through: :concept_property_concepts, source: 'concept_two', conditions: 'concept_property_concepts.property = "equivalent_class"'
  has_many :similar_concepts_a, through: :concept_property_concepts, source: 'concept_two', conditions: 'concept_property_concepts.property = "similar_class"'

  has_many :reverse_concept_property_concepts, class_name: 'ConceptPropertyConcept', foreign_key: 'concept_two_id', order: 'property', dependent: :destroy
  has_many :children, through: :reverse_concept_property_concepts, source: 'concept_one', conditions: 'concept_property_concepts.property = "is_a"'
  has_many :included_by, through: :reverse_concept_property_concepts, source: 'concept_one', conditions: ['concept_property_concepts.property IN (?)', ["includes", "http://purl.org/cpr/includes"]]
  has_many :equivalent_concepts_b, through: :reverse_concept_property_concepts, source: 'concept_one', conditions: 'concept_property_concepts.property = "equivalent_class"'
  has_many :similar_concepts_b, through: :reverse_concept_property_concepts, source: 'concept_one', conditions: 'concept_property_concepts.property = "similar_class"'

  has_many :query_concepts, dependent: :destroy
  has_many :queries, through: :query_concepts

  has_many :report_concepts, dependent: :destroy
  has_many :reports, through: :reports_concepts

  # Virtual attribute for storing DOM tree ID
  attr_accessor :totalnum, :key, :source_id # This should moved to be a mixer/plugin for i2b2 concepts

  # Concept Methods

  def human_name
    @human_name ||= begin
      if not self.display_name.blank?
        self.display_name
      elsif not name.blank?
        self.name.split("#").last.gsub('ANDOR', 'And / Or').titleize
      else
        ''
      end
    end
  end

  def human_units
    self.units.to_s.split('#').last.to_s
  end

  def graph_values(current_user, chart_params)
    categories = []
    result = ''
    error = ''
    all_stats = []
    values = {}
    mapping_values = []

    self.mappings.each do |mapping|
      value_hash = mapping.graph_values_short(current_user, chart_params)
      if value_hash[:error].blank?
        local_values = value_hash[:local_values]
        value_array = value_hash[:value_array]
        all_stats << value_hash[:stats]
        if self.continuous? or self.date?
          mapping_values << local_values
        elsif self.categorical? or self.boolean?
          mapping_values << "[" + value_array.join(',') + "]"
        end
      else
        mapping_values << []
        logger.debug "value_hash[:error]: #{value_hash[:error].inspect}"
      end
    end

    if self.continuous? or self.date?
      all_mapping_values = mapping_values.flatten
      all_integers = false
      all_integers = (all_mapping_values.count{|i| i.denominator != 1} == 0)
      minimum = all_mapping_values.min || 0
      maximum = all_mapping_values.max || 100
      default_max_buckets = 30
      max_buckets = all_integers ? [maximum - minimum + 1, default_max_buckets].min : default_max_buckets
      bucket_size = (maximum - minimum + 1).to_f / max_buckets

      (0..(max_buckets-1)).each do |bucket|
        val_min = (bucket_size * bucket) + minimum
        val_max = bucket_size * (bucket + 1) + minimum
        # Greater or equal to val_min, less than val_max
        # categories << "'#{val_min} to #{val_max}'"
        categories << "'#{val_min.round}'"
      end

      self.mappings.each_with_index do |mapping, index|
        new_values = []
        unless mapping_values[index].blank?
          (0..max_buckets-1).each do |bucket|
            val_min = (bucket_size * bucket) + minimum
            val_max = bucket_size * (bucket + 1) + minimum
            # Greater or equal to val_min, less than val_max
            new_values << mapping_values[index].count{|i| i >= val_min and i < val_max}
          end
          mapping_values[index] = new_values
        end
      end
    end


    self.mappings.each_with_index do |mapping, index|
      unless mapping_values[index].blank?
        key_name = "#{mapping.source.name}.#{mapping.table}.#{mapping.column}"
        if self.continuous? or self.date?
          values[key_name] = mapping_values[index] #local_values
        elsif self.categorical? or self.boolean?
          values[key_name] = mapping_values[index] #"[" + value_array.join(',') + "]"
        end
      end
    end

    if self.continuous? or self.date?
      chart_type = "column"
      chart_element_id = "column_chart_#{self.id}"
    elsif self.categorical? or self.boolean?
      chart_type = "pie"
      chart_element_id = "pie_chart_#{self.id}"
    end

    defaults = { width: "320px", height: 240, units: '', title: '', legend: 'right' }

    defaults.merge!(chart_params)
    defaults.each do |k, v|
      defaults[k] = array_or_string_for_javascript(v) if v.kind_of?(String) or v.kind_of?(Array)
    end

    values.each do |k, v|
      values[k] = array_or_string_for_javascript(v) if v.kind_of?(Array)
    end

    @new_values = {}
    values.each do |k, v|
      @new_values[array_or_string_for_javascript(k)] = v
    end

    values = @new_values

    { values: values, categories: categories, chart_type: chart_type, defaults: defaults, chart_element_id: chart_element_id, error: error, stats: all_stats.join('<br />') }
  end

  def unit_range
    []
  end

  def continuous?
    self.concept_type == 'continuous'
  end

  def categorical?
    self.concept_type == 'categorical'
  end

  def boolean?
    self.concept_type == 'boolean'
  end

  def date?
    self.concept_type == 'datetime'
  end

  def identifier?
    self.concept_type == 'identifier'
  end

  def file_locator?
    self.concept_type == 'file locator'
  end

  def free_text?
    self.concept_type == 'free text'
  end

  def recommended_concepts
    result = []
    self.includes.each do |group_concept|
      result << group_concept.descendants
      result.flatten!.uniq!
    end
    self.children.each do |child|
      result << child
    end
    result = result.uniq.sort{|a,b| a.search_name <=> b.search_name}
    result
  end

  # This function returns all the mappings that should evaluate to true for the given concept.
  # Example a Query for Gender should return results if Male has been marked as boolean, similar query for Age should return results for Age at Time of Test or Study
  # Concept: Age, would find itself (Age, and descendants Age at Time of Test or Study, etc) basically finds all database_concepts that can be used to evaluate the parent concept.
  def mapped_descendants(source = nil)
    result = []
    if source
      all_derived_concepts = source.derived_concepts
      if all_derived_concepts.include?(self)
        # puts "#{self.human_name} included in [#{source.derived_concepts.collect{|concept| concept.human_name}.join(', ')}]"
        # If the concept is in the derived concepts, then try to find the original concepts that reference it.
        all_descendant_ids = self.descendants_and_self.collect{|c| c.id}
        result = source.mappings.where(['concept_id in (?)', all_descendant_ids]) || []
      end
      # puts "#{self.human_name} does not have any mapped names in #{source.name}" if result.blank?
      # puts "#{self.human_name} mapped names in #{source.name} are #{result.collect{|m| "#{m.table}.#{m.column}"}.join(', ')}" unless result.blank?
    end
    result
  end

  def mapped_name(current_user, source = nil)
    result = nil
    if source
      mappings = source.mappings.where(concept_id: self.id) # , status: 'mapped' # Map status should not affect mapping_names
      mapping = mappings.first # Uses the first recorded mapping as a concept should not exist multiple times in a data source
      if mapping
        result_hash = source.sql_codes(current_user)
        sql_open = result_hash[:open]
        sql_close = result_hash[:close]
        result = mapping.table + '.' + sql_open + mapping.column + sql_close
      end
    end
    result
  end

  def descendants
    result = []
    # TODO: Include descendants
    # self.children.each do |child|
    #   unless result.include?(child)
    #     result << ([child] + child.descendants)
    #     result.flatten!
    #     result.uniq!
    #   end
    # end
    result
  end

  def descendants_and_self
    [self] + self.descendants
  end

  # TODO: Units
  def update_unit_type!
    # UNIT_ARRAYS.each do |unit_type, unit_array|
    # self.update_attribute :unit_type, unit_type.to_s if unit_array.collect{|display_name, stored_name| stored_name}.include?(self.units)
    # end
  end

  def update_status!
    self.reload
    result = nil
    if self.continuous?
      result = 'complete'
      [:unit_type, :units].each do |continuous_property|
        result = 'partial' if self.read_attribute(continuous_property).blank?
      end
    elsif self.categorical?
      result = (self.includes.size + self.children.size > 0) ? 'complete' : 'partial'
    elsif self.boolean?
      result = 'complete'
    elsif self.date?
      result = 'complete'
    elsif self.identifier?
      result = 'complete'
    elsif self.file_locator?
      result = 'complete'
    elsif self.free_text?
      result = 'complete'
    end

    self.update_search_name!

    self.update_attributes(status: result)
  end

  def update_search_name!
    self.update_attribute :search_name, self.human_name.downcase
  end

  def self.name_to_uri_and_namespace_and_short_name(name, uri_missing = nil, namespace_missing = nil)
    uri_namespacename = name.split('/')
    namespace_name = uri_namespacename.last.to_s.split('#')
    uri = uri_namespacename[0..-2].join('/')
    namespace = namespace_name[0..-2].join
    short_name = namespace_name.last.to_s

    if short_name =~ /[^\w\-]/
      old_short_name = short_name
      short_name = short_name.titleize.gsub(/[^\w\-]/, '')
      logger.debug "short_name: '#{old_short_name}' invalid, replacing with '#{short_name}'"
    end

    # If the name is in the form '#ShortName' without a uri or namespace prefix,
    # then add in the one's provided as additional input params
    uri = uri_missing if uri.blank? and not uri_missing.blank?
    namespace = namespace_missing if namespace.blank? and not namespace_missing.blank?

    full_name = uri + '/' + namespace + '#' + short_name

    [full_name, uri, namespace, short_name]
  end

  # This function returns a column name for the concept, which basically takes the qname and replaces the colon with an underscore
  # cname is short for column name
  def cname
    self.qname.gsub(/[-:\s]/, '_')
  end

  # This turns http://purl.org/biotop/1.0/biotop.owl#Action into biotop:Action
  def qname
    self.name.blank? ? '' : self.name.split('#').first.to_s.split('/').last.to_s.split('.').first.to_s + ':' + self.name.split('#').last.to_s
  end

  def equivalent_concepts
    (equivalent_concepts_a + equivalent_concepts_b).uniq
  end

  def similar_concepts
    (similar_concepts_a + similar_concepts_b).uniq
  end

  def ancestors(concept_type_array = ['all'])
    result = []
    self.parents.each do |parent|
      unless result.include?(parent)
        if concept_type_array.include?('all') or concept_type_array.include?(parent.concept_type)
          result << ([parent] + parent.ancestors(concept_type_array))
        else
          # puts "Concept '#{parent.human_name}' concept type '#{if parent.concept_type.blank? then 'nil' else parent.concept_type end}' is not in concept type array #{concept_type_array.inspect}"
          result << parent.ancestors(concept_type_array)
        end
        result.flatten!
        result.uniq!
      end
    end
    result
  end

  def ancestors_and_self(concept_type_array = ['all'])
    if concept_type_array.include?('all') or concept_type_array.include?(self.concept_type)
      return [self] + self.ancestors(concept_type_array)
    else
      return self.ancestors(concept_type_array)
    end
  end

  # include ActionView::Helpers::UrlHelper # For array_or_string_for_javascript  (also in ScriptaculousHelper)
  def array_or_string_for_javascript(option)
    if option.kind_of?(Array)
      "['#{option.join('\',\'')}']"
    elsif !option.nil?
      "'#{option}'"
    end
  end
end
