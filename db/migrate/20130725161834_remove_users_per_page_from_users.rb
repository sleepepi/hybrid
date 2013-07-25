class RemoveUsersPerPageFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :users_per_page, :integer, default: 10, null: false
  end
end
