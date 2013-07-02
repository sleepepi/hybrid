class RemoveTermsTable < ActiveRecord::Migration
  def up
    drop_table :terms
  end

  def down
    create_table :terms do |t|
      t.integer :concept_id
      t.string  :name
      t.string  :version
      t.string  :search_name
      t.boolean :internal,    :default => false, :null => false

      t.timestamps
    end

    add_index :terms, :concept_id
  end
end
