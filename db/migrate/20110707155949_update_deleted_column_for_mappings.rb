class UpdateDeletedColumnForMappings < ActiveRecord::Migration
  def up
    change_column :mappings, :deleted, :boolean, :null => false, :default => false
  end

  def down
    change_column :mappings, :deleted, :boolean, :null => true, :default => nil
  end
end
