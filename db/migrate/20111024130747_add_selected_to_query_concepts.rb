class AddSelectedToQueryConcepts < ActiveRecord::Migration
  def change
    add_column :query_concepts, :selected, :boolean, :default => false, :null => false
  end
end
