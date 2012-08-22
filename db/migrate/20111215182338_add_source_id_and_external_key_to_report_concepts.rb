class AddSourceIdAndExternalKeyToReportConcepts < ActiveRecord::Migration
  def change
    add_column :report_concepts, :source_id, :integer
    add_column :report_concepts, :external_key, :string
  end
end
