class AddLevelToQueryConcepts < ActiveRecord::Migration
  def change
    add_column :query_concepts, :level, :integer, :default => 0, :null => false
  end
end
