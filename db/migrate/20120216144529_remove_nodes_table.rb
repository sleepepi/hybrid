class RemoveNodesTable < ActiveRecord::Migration
  def self.up
    drop_table :nodes
  end

  def self.down
    create_table :nodes do |t|
      t.string :name
      t.string :version
      t.string :url
      t.text :description
      t.string :status, default: 'pending', null: false
      t.text :public_key
      t.text :private_key
      t.boolean :deleted, default: false, null: false

      t.timestamps
    end
  end
end
