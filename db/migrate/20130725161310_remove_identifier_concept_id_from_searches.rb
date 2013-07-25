class RemoveIdentifierConceptIdFromSearches < ActiveRecord::Migration
  def change
    remove_column :searches, :identifier_concept_id, :integer
  end
end
