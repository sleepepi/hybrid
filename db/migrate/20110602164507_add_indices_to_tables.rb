class AddIndicesToTables < ActiveRecord::Migration
  def self.up
    add_index :authentications, :user_id
    add_index :concepts, :ontology_id
    add_index :mappings, :concept_id
    add_index :mappings, :source_id
    add_index :ontologies, :user_id
    add_index :queries, :user_id
    add_index :query_concepts, :concept_id
    add_index :query_concepts, :query_id
    add_index :query_sources, :query_id
    add_index :query_sources, :source_id
    add_index :query_users, :query_id
    add_index :query_users, :user_id
    add_index :source_joins, :source_id
    add_index :sources, :node_id
    add_index :terms, :concept_id
  end

  def self.down
    remove_index :authentications, :user_id
    remove_index :concepts, :ontology_id
    remove_index :mappings, :concept_id
    remove_index :mappings, :source_id
    remove_index :ontologies, :user_id
    remove_index :queries, :user_id
    remove_index :query_concepts, :concept_id
    remove_index :query_concepts, :query_id
    remove_index :query_sources, :query_id
    remove_index :query_sources, :source_id
    remove_index :query_users, :query_id
    remove_index :query_users, :user_id
    remove_index :source_joins, :source_id
    remove_index :sources, :node_id
    remove_index :terms, :concept_id    
  end
end
