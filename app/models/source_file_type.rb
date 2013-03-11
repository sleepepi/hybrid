class SourceFileType < ActiveRecord::Base
  # Named Scopes
  scope :current, -> { all }  # deleted: false

  # Model Validation
  validates_presence_of :file_type_id
  validates_uniqueness_of :file_type_id, scope: :source_id

  # Model Relationships
  belongs_to :source
  belongs_to :file_type

  # Source File Type Methods

  def name
    "ID ##{self.id}"
  end
end
