class Join < ActiveRecord::Base

  # Named Scopes
  scope :current, -> { all }
  scope :search, lambda { |arg| where( [ 'LOWER(from_table) LIKE ? or LOWER(from_column) LIKE ? or LOWER(to_table) LIKE ? or LOWER(to_column) LIKE ?', arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%') ] ) }
  scope :with_from_table, lambda { |arg| where( ["from_table IN (?) or 'all' IN (?)", arg, arg] ) }
  scope :with_to_table, lambda { |arg| where( ["to_table IN (?) or 'all' IN (?)", arg, arg] ) }
  scope :with_table, lambda { |arg| where( ["from_table IN (?) or to_table IN (?) or 'all' IN (?)", arg, arg, arg] ) }

  # Model Relationships
  belongs_to :source

  # Model Validation
  validates_presence_of :source_id, :from_table, :from_column, :to_table, :to_column

  def name
    "ID ##{self.id}"
  end

end
