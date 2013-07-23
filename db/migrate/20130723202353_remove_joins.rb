class RemoveJoins < ActiveRecord::Migration
  def self.up
    drop_table :joins
  end

  def self.down
    create_table :joins do |t|
      t.integer :source_id
      t.string :from_table
      t.string :from_column
      t.string :to_table
      t.string :to_column

      t.timestamps
    end

    add_index :joins, :source_id
  end
end
