class AddSourceIdAndExternalKeyToQueryConcepts < ActiveRecord::Migration
  def change
    add_column :query_concepts, :source_id, :integer
    add_column :query_concepts, :external_key, :string
  end
end
