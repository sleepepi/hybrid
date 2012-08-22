class CreateMappings < ActiveRecord::Migration
  def self.up
    create_table :mappings do |t|
      t.integer :source_id
      t.integer :concept_id
      t.string :value
      t.string :table
      t.string :column
      t.string :column_value
      t.string :units
      t.string :status
      t.boolean :deleted

      t.timestamps
    end
  end

  def self.down
    drop_table :mappings
  end
end
