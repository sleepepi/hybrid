class CreateQuerySources < ActiveRecord::Migration
  def self.up
    create_table :query_sources do |t|
      t.integer :query_id
      t.integer :source_id
      t.integer :node_id
      t.timestamps
    end
  end

  def self.down
    drop_table :query_sources
  end
end
