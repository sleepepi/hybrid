class ModifyMappingsTable < ActiveRecord::Migration
  def change
    remove_column :mappings, :value, :string
    remove_column :mappings, :column_value, :string
    add_index :mappings, :variable_id
  end
end
