class RemoveUriNamespaceAndNameFromConcepts < ActiveRecord::Migration
  def up
    remove_column :concepts, :name
    remove_column :concepts, :namespace
    remove_column :concepts, :uri
  end

  def down
    add_column :concepts, :name, :string
    add_column :concepts, :namespace, :string
    add_column :concepts, :uri, :string
  end
end
