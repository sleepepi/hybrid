class UpdateQueryConceptColumn < ActiveRecord::Migration
  def up
    remove_column :query_concepts, :concept_id
    add_column :query_concepts, :variable_id, :integer
  end

  def down
    remove_column :query_concepts, :variable_id
    add_column :query_concepts, :concept_id, :integer
  end
end
