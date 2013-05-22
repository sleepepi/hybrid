class Concept < ActiveRecord::Base

  SENSITIVITY = [["0) Not Sensitive","0"], ["1) Requires Approval","1"], ["2) Requires Approval with Documentation","2"]]

  CONCEPT_TYPE = ['boolean', 'categorical', 'continuous', 'datetime', 'identifier', 'file locator', 'free text'].collect{|i| [i,i]}

  # Named Scopes
  scope :current, -> { all }  # deleted: false
  scope :searchable, lambda { |*args|  where("concepts.concept_type IS NOT NULL") }
  scope :with_concept_type, lambda { |*args|  where(["concepts.concept_type IN (?) or 'all' IN (?)", args.first, args.first]) }

  scope :with_source, lambda { |*args|  where(["concepts.id in (select concept_id from mappings where mappings.source_id IN (?) and mappings.status IN (?) and mappings.deleted = ?)", args.first, ['mapped', 'unmapped', 'derived'], false] ) } # TODO: Status of mapping no longer matters
  scope :with_folder, lambda { |*args| where(["LOWER(concepts.folder) LIKE ? or ? IS NULL", args.first.to_s + ':%', args.first]) }
  scope :with_exact_folder, lambda { |*args| where(["LOWER(concepts.folder) LIKE ? or ('Uncategorized' = ? and (concepts.folder IS NULL or concepts.folder = ''))", args.first, args.first]) }
  scope :with_exact_folder_or_subfolder, lambda { |*args| where(["LOWER(concepts.folder) LIKE ? or LOWER(concepts.folder) LIKE ? or ('Uncategorized' = ? and (concepts.folder IS NULL or concepts.folder = ''))", args.first, args.first.to_s + ':%', args.first]) }

  scope :with_dictionary, lambda { |*args| where(["concepts.dictionary_id IN (?) or 'all' IN (?)", args.first, args.first]) }

  scope :with_report, lambda { |*args| where(["? = '' or concepts.id in (select concept_id from report_concepts where report_concepts.report_id = ?)", args.first, args.first]) }

  scope :search, lambda { |*args| where([ 'LOWER(search_name) LIKE ? or LOWER(search_name) LIKE ? or concepts.id in (select concept_id from terms where LOWER(terms.search_name) LIKE ? or LOWER(terms.search_name) LIKE ?)', args.first + '%', '% ' + args.first + '%', args.first + '%', '% ' + args.first + '%' ]) }

  scope :exactly, lambda { |*args| where([ 'LOWER(short_name) = ? or LOWER(short_name) = ? or LOWER(search_name) = ? or LOWER(search_name) = ? or concepts.id in (select concept_id from terms where LOWER(terms.search_name) = ? or LOWER(terms.search_name) = ?)', args.first, args[1], args.first, args[1], args.first, args[1] ]) }

  # Model Validation
  validates_presence_of :short_name
  validates_uniqueness_of :short_name, scope: :dictionary_id

  validates_format_of :short_name,
                      with: /\A[\w\-]+\Z/,
                      message: "must contain only letters, digits, underscores, and dashes."

  # Model Relationships

  has_many :mappings, dependent: :destroy
  belongs_to :dictionary
  has_many :sources, -> { where(deleted: false).order('sources.name') }, through: :mappings

  has_many :terms, -> { order :name }, dependent: :destroy
  has_many :external_terms, -> { where(internal: false).order('terms.name') }, class_name: "Term", dependent: :destroy
  has_many :internal_terms, -> { where(internal: true).order('terms.name') }, class_name: "Term", dependent: :destroy

  has_many :concept_property_concepts, foreign_key: 'concept_one_id', dependent: :destroy
  has_many :parents, through: :concept_property_concepts, source: 'concept_two'

  has_many :reverse_concept_property_concepts, class_name: 'ConceptPropertyConcept', foreign_key: 'concept_two_id', dependent: :destroy
  has_many :children, through: :reverse_concept_property_concepts, source: 'concept_one'

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
      elsif not short_name.blank?
        self.short_name.gsub('ANDOR', 'And / Or').titleize
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
          mapping_values << value_array # "[" + value_array.join(',') + "]"
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
        categories << "#{val_min.round}"
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

  def update_search_name!
    self.update_column :search_name, self.human_name.downcase unless self.new_record?
  end

  # This function returns a column name for the concept
  # constructed from the dictionary name and the short_name
  def cname
    self.dictionary.name.downcase.gsub(/[^a-z0-9]/, '_') + '_' + self.short_name.downcase.gsub(/[^a-z0-9]/, '_')
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

end
