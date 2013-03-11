class FileType < ActiveRecord::Base

  # Named Scopes
  scope :current, -> { all }  # deleted: false
  scope :available, -> { where visible: true }

  scope :with_report, lambda { |arg| where( [ "? = '' or concepts.id in (select concept_id from report_concepts where report_concepts.report_id = ?)", arg, arg ] ) }
  scope :with_source, lambda { |arg| where( [ "file_types.id IN (select file_type_id from source_file_types where source_file_types.source_id IN (?))", arg ] ) }

  # Model Validation

  validates_presence_of :name, :extension

  # Model Relationships
  belongs_to :user
  belongs_to :dictionary

  has_many :source_file_types, dependent: :destroy
  has_many :sources, -> { order :name }, through: :source_file_types

  # FileType Methods

  def name_and_extension
    self.name.to_s + ' ' + self.extension.to_s
  end

  def name_and_short_extension
    "#{self.name} (#{self.extension.split('.').last.downcase})"
  end

  # Returns true if the user can download the file_type from at least
  # one of the sources
  def user_can_download?(current_user, selected_sources)
    (self.sources & selected_sources).each do |source|
      return true if source.user_has_action?(current_user, "download files")
    end
    false
  end
end
