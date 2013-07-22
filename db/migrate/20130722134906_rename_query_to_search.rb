class RenameQueryToSearch < ActiveRecord::Migration
  def up
    rename_table :queries, :searches

    remove_index :query_concepts, :query_id
    remove_index :query_sources, :query_id
    remove_index :query_users, :query_id

    rename_column :query_concepts, :query_id, :search_id
    rename_column :query_sources, :query_id, :search_id
    rename_column :query_users, :query_id, :search_id
    rename_column :reports, :query_id, :search_id
    rename_column :users, :current_query_id, :current_search_id

    add_index :query_concepts, :search_id
    add_index :query_sources, :search_id
    add_index :query_users, :search_id
  end


  def down
    rename_table :searches, :queries

    remove_index :query_concepts, :search_id
    remove_index :query_sources, :search_id
    remove_index :query_users, :search_id

    rename_column :query_concepts, :search_id, :query_id
    rename_column :query_sources, :search_id, :query_id
    rename_column :query_users, :search_id, :query_id
    rename_column :reports, :search_id, :query_id
    rename_column :users, :current_search_id, :current_query_id

    add_index :query_concepts, :query_id
    add_index :query_sources, :query_id
    add_index :query_users, :query_id
  end

end
