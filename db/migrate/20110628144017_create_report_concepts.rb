class CreateReportConcepts < ActiveRecord::Migration
  def self.up
    create_table :report_concepts do |t|
      t.integer :report_id
      t.integer :concept_id
      t.integer :position,  :default => 0, :null => false
      t.boolean :strata,    :default => false, :null => false
      t.string :statistic,  :default => '', :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :report_concepts
  end
end
