class RemoveRestraintFromSourceFileRepository < ActiveRecord::Migration
  def up
    change_column :sources, :repository, :string, default: nil, null: true
  end

  def down
    change_column :sources, :repository, :string, default: 'ftp', null: false
  end
end
