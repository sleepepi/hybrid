class Variable < ActiveRecord::Base

  TYPE = ['identifier', 'choices', 'string', 'text', 'integer', 'numeric', 'date', 'time', 'file'].sort.collect{|i| [i,i]}

  # Concerns
  include Searchable

  # Named Scopes
  scope :current, -> { all }

  # Model Validation
  validates_presence_of :name, :display_name, :variable_type, :dictionary_id
  validates_format_of :name, with: /\A[a-z]\w*\Z/i
  validates :name, length: { maximum: 32 }
  validates_uniqueness_of :name, scope: :dictionary_id

  # Model Relationships
  belongs_to :dictionary
  belongs_to :domain
  has_many :tags, dependent: :destroy

end
