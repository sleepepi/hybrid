class CreateFileTypes < ActiveRecord::Migration
  def change
    create_table :file_types do |t|
      t.string :name
      t.string :extension
      t.text :description
      t.boolean :visible, :default => true, :null => false
      t.integer :user_id
      t.integer :source_id
      t.integer :ontology_id

      t.timestamps
    end
  end
end
