class CreateOntologies < ActiveRecord::Migration
  def self.up
    create_table :ontologies do |t|
      t.string   :name
      t.text     :description
      t.string   :status
      t.integer  :user_id
      t.boolean  :visible,     :default => true,  :null => false
      t.boolean  :deleted,     :default => false, :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :ontologies
  end
end
