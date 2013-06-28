class RemoveUnitTypeAndDataTypeFromConcepts < ActiveRecord::Migration
  def up
    remove_column :concepts, :unit_type
    remove_column :concepts, :data_type
  end

  def down
    add_column :concepts, :unit_type, :string
    add_column :concepts, :data_type, :string
  end
end
