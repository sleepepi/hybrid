class ChangeConceptIdToVariableIdInMappings < ActiveRecord::Migration
  def up
    remove_column :mappings, :concept_id
    add_column :mappings, :variable_id, :integer
  end

  def down
    remove_column :mappings, :variable_id
    add_column :mappings, :concept_id, :integer
  end
end
