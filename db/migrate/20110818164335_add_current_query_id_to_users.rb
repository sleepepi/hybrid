class AddCurrentQueryIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_query_id, :integer
  end
end
