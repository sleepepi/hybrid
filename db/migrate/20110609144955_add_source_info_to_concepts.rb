class AddSourceInfoToConcepts < ActiveRecord::Migration
  def self.up
    add_column :concepts, :source_name, :string
    rename_column :concepts, :source, :source_file
    add_column :concepts, :source_description, :text
  end

  def self.down
    remove_column :concepts, :source_name
    rename_column :concepts, :source_file, :source
    remove_column :concepts, :source_description
  end
end
