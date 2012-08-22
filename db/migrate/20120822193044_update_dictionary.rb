class UpdateDictionary < ActiveRecord::Migration
  def up
    remove_index :ontologies, :user_id
    rename_table :ontologies, :dictionaries
    add_index :dictionaries, :user_id
    remove_index :concepts, :ontology_id
    rename_column :concepts, :ontology_id, :dictionary_id
    add_index :concepts, :dictionary_id
    rename_column :file_types, :ontology_id, :dictionary_id
  end

  def down
    rename_column :file_types, :dictionary_id, :ontology_id
    remove_index :concepts, :dictionary_id
    rename_column :concepts, :dictionary_id, :ontology_id
    add_index :concepts, :ontology_id
    remove_index :dictionaries, :user_id
    rename_table :dictionaries, :ontologies
    add_index :ontologies, :user_id
  end
end
