class RemoveConceptsTable < ActiveRecord::Migration
  def up
    drop_table :concepts
  end

  def down
    create_table :concepts do |t|
      t.integer :dictionary_id
      t.string  :display_name
      t.string  :search_name
      t.string  :short_name
      t.string  :version
      t.text    :description
      t.string  :concept_type
      t.string  :units
      t.string  :formula
      t.string  :source_file
      t.string  :sensitivity,   default: '0',   null: false
      t.boolean :commonly_used, default: false, null: false
      t.string  :folder
      t.string  :source_name
      t.text    :source_description

      t.timestamps
    end

    add_index :concepts, :dictionary_id
  end
end
