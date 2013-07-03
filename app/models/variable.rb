class Variable < ActiveRecord::Base

  TYPE = ['identifier', 'choices', 'string', 'text', 'integer', 'numeric', 'date', 'time', 'file'].sort.collect{|i| [i,i]}

  # Concerns
  include Searchable

  # Named Scopes
  scope :current, -> { all }
  scope :with_source, lambda { |arg| where( [ "variables.id in (select variable_id from mappings where mappings.variable_id = variables.id and mappings.source_id IN (?))", arg ] ) }


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

end
