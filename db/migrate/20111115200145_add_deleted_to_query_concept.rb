class AddDeletedToQueryConcept < ActiveRecord::Migration
  def change
    add_column :query_concepts, :deleted, :boolean, :default => false, :null => false
  end
end
