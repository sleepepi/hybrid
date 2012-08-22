class AddSourceToIdToSourceJoin < ActiveRecord::Migration
  def self.up
    add_column :source_joins, :source_to_id, :integer
  end

  def self.down
    remove_column :source_joins, :source_to_id
  end
end
