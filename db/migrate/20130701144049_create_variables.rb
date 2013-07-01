class CreateVariables < ActiveRecord::Migration
  def change
    create_table :variables do |t|
      t.text :folder
      t.string :name
      t.string :display_name
      t.text :description
      t.string :variable_type
      t.integer :dictionary_id
      t.integer :domain_id
      t.string :units
      t.string :version
      t.string :calculation
      t.string :design_file
      t.string :design_name
      t.string :sensitivity, null: false, default: '0'
      t.boolean :commonly_used, null: false, default: false

      t.timestamps
    end

    add_index :variables, :dictionary_id
    add_index :variables, :domain_id
  end
end
