class UpdateQueryConceptColumn < ActiveRecord::Migration
  def up
    remove_index :query_concepts, :concept_id
    remove_column :query_concepts, :concept_id
    add_column :query_concepts, :variable_id, :integer
    add_index :query_concepts, :variable_id
  end

  def down
    remove_index :query_concepts, :variable_id
    remove_column :query_concepts, :variable_id
    add_column :query_concepts, :concept_id, :integer
    add_index :query_concepts, :concept_id
  end
end
