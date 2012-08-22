class RemoveOverallGroupFromQueries < ActiveRecord::Migration
  def up
    remove_column :queries, :overall_group
    remove_column :queries, :stage
  end

  def down
    add_column :queries, :overall_group, :string, :default => "all", :null => false
    add_column :queries, :stage, :integer, :default => 1, :null => false
  end
end
