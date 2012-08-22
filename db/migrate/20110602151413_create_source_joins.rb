class CreateSourceJoins < ActiveRecord::Migration
  def self.up
    create_table :source_joins do |t|
      t.integer :source_id
      t.string :from_table
      t.string :from_column
      t.string :to_table
      t.string :to_column

      t.timestamps
    end
  end

  def self.down
    drop_table :source_joins
  end
end
