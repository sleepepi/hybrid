class Variable < ActiveRecord::Base

  TYPE = ['identifier', 'choices', 'string', 'text', 'integer', 'numeric', 'date', 'time', 'file'].sort.collect{|i| [i,i]}

  # Concerns
  # include Searchable

  # Named Scopes
  scope :current, -> { all }
  scope :search, lambda { |arg| where("LOWER(name) LIKE ? or LOWER(display_name) LIKE ? or LOWER(description) LIKE ? or variables.id in ( select tags.variable_id from tags where LOWER(tags.name) LIKE ? )", arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%')) }
  scope :with_source, lambda { |arg| where( "variables.id in (select variable_id from mappings where mappings.variable_id = variables.id and mappings.source_id IN (?))", arg ) }
  scope :with_folder, lambda { |arg| where( "LOWER(folder) LIKE ? or ? IS NULL", "#{arg.to_s.downcase}/%", arg ) }
  scope :with_exact_folder, lambda { |arg| where( "LOWER(folder) LIKE ? or ('Uncategorized' = ? and (folder IS NULL or folder = ''))", arg.to_s.downcase, arg ) }
  scope :with_exact_folder_or_subfolder, lambda { |arg| where( "LOWER(folder) LIKE ? or LOWER(folder) LIKE ? or ('Uncategorized' = ? and (folder IS NULL or folder = ''))", arg.to_s.downcase, arg.to_s.downcase + '/%', arg ) }

  # Model Validation
  validates_presence_of :name, :display_name, :variable_type, :dictionary_id
  validates_format_of :name, with: /\A[a-z]\w*\Z/i
  validates :name, length: { maximum: 32 }
  validates_uniqueness_of :name, scope: :dictionary_id

  # Model Relationships
  belongs_to :dictionary
  belongs_to :domain
  has_many :tags, dependent: :destroy
  has_many :mappings, dependent: :destroy
  has_many :query_concepts, dependent: :destroy
  has_many :report_concepts, dependent: :destroy
  has_many :sources, -> { where(deleted: false).uniq.order('sources.name') }, through: :mappings

  def mapped_name(current_user, source = nil)
    result = nil
    if source
      mappings = source.mappings.where(variable_id: self.id)
      mapping = mappings.first
      if mapping
        result_hash = source.sql_codes(current_user)
        sql_open = result_hash[:open]
        sql_close = result_hash[:close]
        result = mapping.table + '.' + sql_open + mapping.column + sql_close
      end
    end
    result
  end

  def domain_values
    if self.domain
      self.domain.values
    else
      []
    end
  end

  def folder_path_and_folder(current_folder)
    r = Regexp.new("^#{current_folder}/")
    if self.folder.blank?
      ['Uncategorized', 'Uncategorized']
    else
      variable_folder = self.folder.to_s.gsub(r, '').split('/').first
      [[current_folder, variable_folder].compact.join('/'), variable_folder]
    end
  end

  def design_name_or_filename
    self.design_name.blank? ? self.design_file : self.design_name
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
        if ['numeric', 'integer', 'date'].include?(self.variable_type)
          mapping_values << local_values
        elsif self.variable_type == 'choices'
          mapping_values << value_array
        end
      else
        mapping_values << []
      end
    end

    if ['numeric', 'integer', 'date'].include?(self.variable_type)
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
        if ['numeric', 'integer', 'date'].include?(self.variable_type)
          values[key_name] = mapping_values[index] #local_values
        elsif self.variable_type == 'choices'
          values[key_name] = mapping_values[index] #"[" + value_array.join(',') + "]"
        end
      end
    end

    if ['numeric', 'integer', 'date'].include?(self.variable_type)
      chart_type = "column"
    elsif self.variable_type == 'choices'
      chart_type = "pie"
    end

    chart_element_id = "variable_chart_#{self.id}"

    defaults = { width: "320px", height: 240, units: '', title: '', legend: 'right' }

    defaults.merge!(chart_params)

    { values: values, categories: categories, chart_type: chart_type, defaults: defaults, chart_element_id: chart_element_id, error: error, stats: all_stats.join('<br />') }
  end

end
