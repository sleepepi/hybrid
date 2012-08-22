class CreateSourceRules < ActiveRecord::Migration
  def self.up
    create_table :source_rules do |t|
      t.integer :source_id
      t.text :actions
      t.text :users
      t.boolean :blocked, :default => false, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :source_rules
  end
end
