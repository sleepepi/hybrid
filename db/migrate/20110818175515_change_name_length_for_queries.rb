class ChangeNameLengthForQueries < ActiveRecord::Migration
  def up
    change_column :queries, :name, :string, :limit => 255
  end

  def down
    change_column :queries, :name, :string, :limit => 50
  end
end
