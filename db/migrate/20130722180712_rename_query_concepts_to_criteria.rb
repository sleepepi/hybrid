class RenameQueryConceptsToCriteria < ActiveRecord::Migration
  def change
    rename_table :query_concepts, :criteria
  end
end
