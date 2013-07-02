class RemoveConceptPropertyConcepts < ActiveRecord::Migration
  def up
    drop_table :concept_property_concepts
  end

  def down
    create_table :concept_property_concepts do |t|
      t.integer :concept_one_id
      t.integer :concept_two_id
      t.string  :version
      t.timestamps
    end

    add_index :concept_property_concepts, :concept_one_id
    add_index :concept_property_concepts, :concept_two_id
    add_index :concept_property_concepts, [:concept_one_id, :concept_two_id], :name => 'cpc_on_one_and_two'
  end
end
