class AddMappingIdToCriteria < ActiveRecord::Migration
  def change
    add_column :criteria, :mapping_id, :integer
    remove_column :criteria, :source_id, :integer
  end
end
