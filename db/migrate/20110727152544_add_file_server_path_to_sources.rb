class AddFileServerPathToSources < ActiveRecord::Migration
  def change
    add_column :sources, :file_server_path, :string
  end
end
