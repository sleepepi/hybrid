class RemoveConceptIdFromReportConcepts < ActiveRecord::Migration
  def up
    remove_column :report_concepts, :concept_id
    remove_column :report_concepts, :external_key
    add_column :report_concepts, :variable_id, :integer
  end

  def down
    remove_column :report_concepts, :variable_id
    add_column :report_concepts, :external_key, :string
    add_column :report_concepts, :concept_id, :integer
  end
end
