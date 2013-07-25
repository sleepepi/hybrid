class ChangeConceptIdToVariableIdInMappings < ActiveRecord::Migration
  def up
    remove_index :mappings, :concept_id
    remove_column :mappings, :concept_id
    add_column :mappings, :variable_id, :integer
    add_index :mappings, :variable_id
  end

  def down
    remove_index :mappings, :variable_id
    remove_column :mappings, :variable_id
    add_column :mappings, :concept_id, :integer
    add_index :mappings, :concept_id
  end
end
