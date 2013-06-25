class RemoveSourceToIdFromJoins < ActiveRecord::Migration
  def self.up
    remove_column :joins, :source_to_id
  end

  def self.down
    add_column :joins, :source_to_id, :integer
  end
end
