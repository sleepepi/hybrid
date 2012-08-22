class CreateSources < ActiveRecord::Migration
  def self.up
    create_table :sources do |t|
      t.integer  :node_id
      t.string   :name
      t.text     :description
      t.integer  :user_id
      t.string   :host
      t.integer  :port
      t.string   :wrapper,           :default => 'mysql', :null => false
      t.string   :database
      t.string   :username
      t.string   :password
      t.boolean  :deleted,           :default => false, :null => false
      t.boolean  :visible,           :default => true,  :null => false
      t.string   :file_server_type,  :default => 'ftp', :null => false
      t.string   :file_server_host
      t.string   :file_server_login
      t.string   :file_server_password

      t.timestamps
    end
  end

  def self.down
    drop_table :sources
  end
end
