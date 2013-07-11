class Variable < ActiveRecord::Base

  TYPE = ['identifier', 'choices', 'string', 'text', 'integer', 'numeric', 'date', 'time', 'file'].sort.collect{|i| [i,i]}

  # Concerns
  include Searchable

  # Named Scopes
  scope :current, -> { all }
  scope :with_source, lambda { |arg| where( "variables.id in (select variable_id from mappings where mappings.variable_id = variables.id and mappings.source_id IN (?))", arg ) }
  scope :with_folder, lambda { |arg| where( "LOWER(folder) LIKE ? or ? IS NULL", "#{arg.to_s.downcase}/%", arg ) }
  scope :with_exact_folder, lambda { |arg| where( "LOWER(folder) LIKE ? or ('Uncategorized' = ? and (folder IS NULL or folder = ''))", arg.to_s.downcase, arg ) }


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

end
