class RemoveDeletedAndStatusAndUnitsFromMappings < ActiveRecord::Migration
  def up
    Mapping.where( deleted: true ).delete_all
    remove_column :mappings, :deleted
    remove_column :mappings, :status
    remove_column :mappings, :units
  end

  def down
    add_column :mappings, :deleted, :boolean, null: false, default: false
    add_column :mappings, :status, :string
    add_column :mappings, :units, :string
  end
end
