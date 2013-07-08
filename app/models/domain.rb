class Domain < ActiveRecord::Base
  serialize :options, Array

  # Concerns
  include Searchable

  # Named Scopes
  scope :current, -> { all }

  # Model Validation
  validates_presence_of :name, :dictionary_id
  validates_format_of :name, with: /\A[a-z]\w*\Z/i
  validates :name, length: { maximum: 30 }
  validates_uniqueness_of :name, scope: :dictionary_id

  # Model Relationships
  belongs_to :dictionary
  has_many :variables

  # Domain Methods

  def values
    self.options.collect{ |option| option[:value] }
  end

end
