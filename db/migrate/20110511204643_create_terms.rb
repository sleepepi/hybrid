class CreateTerms < ActiveRecord::Migration
  def self.up
    create_table :terms do |t|
      t.integer :concept_id
      t.string  :name
      t.string  :version
      t.string  :search_name
      t.boolean :internal,    :default => false, :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :terms
  end
end
