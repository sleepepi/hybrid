class RenameSourceJoinToJoin < ActiveRecord::Migration
  def change
    rename_table :source_joins, :joins
  end
end
