class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :variable_id

      t.timestamps
    end

    add_index :tags, :variable_id
  end
end
