class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.integer  "user_id"
      t.string   "name",                  :limit => 50
      t.string   "description",           :limit => 200
      t.boolean  "deleted",               :default => false, :null => false
      t.string   "overall_group",         :default => "all", :null => false
      t.boolean  "negated",               :default => false, :null => false
      t.integer  "stage",                 :default => 1,     :null => false
      t.integer  "identifier_concept_id"
      
      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
