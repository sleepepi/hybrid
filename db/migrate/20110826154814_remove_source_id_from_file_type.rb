class RemoveSourceIdFromFileType < ActiveRecord::Migration
  def up
    remove_column :file_types, :source_id
  end

  def down
    add_column :file_types, :source_id, :integer
  end
end
