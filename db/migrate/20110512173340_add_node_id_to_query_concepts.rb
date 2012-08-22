class AddNodeIdToQueryConcepts < ActiveRecord::Migration
  def self.up
    add_column :query_concepts, :node_id, :integer
  end

  def self.down
    remove_column :query_concepts, :node_id
  end
end
