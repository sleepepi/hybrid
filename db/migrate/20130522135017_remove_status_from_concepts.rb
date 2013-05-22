class RemoveStatusFromConcepts < ActiveRecord::Migration
  def up
    remove_column :concepts, :status
  end

  def down
    add_column :concepts, :status, :string
  end
end
