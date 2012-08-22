class AddHistoryToQuery < ActiveRecord::Migration
  def change
    add_column :queries, :history, :text
    add_column :queries, :history_position, :integer, :default => 0, :null => false
  end
end
