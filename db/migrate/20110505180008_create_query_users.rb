class CreateQueryUsers < ActiveRecord::Migration
  def self.up
    create_table :query_users do |t|
      t.integer  :user_id
      t.integer  :query_id
      t.timestamps
    end
  end

  def self.down
    drop_table :query_users
  end
end
