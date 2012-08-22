class CreateQueryConcepts < ActiveRecord::Migration
  def self.up
    create_table :query_concepts do |t|
      t.integer :query_id
      t.integer :concept_id
      t.integer :grouping
      t.string  :value
      t.integer :position
      t.boolean :negated,       :default => false, :null => false
      t.boolean :group_negated, :default => false, :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :query_concepts
  end
end
