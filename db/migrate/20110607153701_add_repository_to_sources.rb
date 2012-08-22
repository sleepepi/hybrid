class AddRepositoryToSources < ActiveRecord::Migration
  def self.up
    rename_column :sources, :file_server_type, :repository
  end

  def self.down
    rename_column :sources, :repository, :file_server_type
  end
end
