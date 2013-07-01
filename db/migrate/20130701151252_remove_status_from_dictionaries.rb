class RemoveStatusFromDictionaries < ActiveRecord::Migration
  def up
    remove_column :dictionaries, :status
  end

  def down
    add_column :dictionaries, :status, :string
  end
end
