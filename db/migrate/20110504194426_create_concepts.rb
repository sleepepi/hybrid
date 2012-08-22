class CreateConcepts < ActiveRecord::Migration
  def self.up
    create_table :concepts do |t|
      t.integer :ontology_id

      t.string  :display_name
      t.string  :search_name
      t.string  :short_name
      t.string  :namespace
      t.string  :uri
      
      t.string  :name
      
      t.string  :version
      
      t.text    :description
      t.string  :concept_type
      t.string  :units
      t.string  :unit_type
      t.integer :minimum
      t.integer :maximum
      t.string  :status
      t.string  :data_type
      t.string  :formula
      t.string  :source
      t.string  :sensitivity,   :default => "0",   :null => false

      t.boolean :commonly_used, :default => false, :null => false
      t.string  :folder
      
      t.timestamps
    end
  end

  def self.down
    drop_table :concepts
  end
end
