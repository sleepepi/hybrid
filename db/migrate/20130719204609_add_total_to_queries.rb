class AddTotalToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :total, :integer, null: false, default: 0
  end
end
