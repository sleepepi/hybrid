class RemoveNodeIdFromTables < ActiveRecord::Migration
  def up
    remove_index :sources, :node_id
    remove_column :query_concepts, :node_id
    remove_column :query_sources, :node_id
    remove_column :sources, :node_id
  end

  def down
    add_column :query_concepts, :node_id, :integer
    add_column :query_sources, :node_id, :integer
    add_column :sources, :node_id, :integer
    add_index :sources, :node_id
  end
end
