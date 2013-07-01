class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.text :folder
      t.string :name
      t.text :options
      t.integer :dictionary_id
      t.string :version

      t.timestamps
    end

    add_index :domains, :dictionary_id
  end
end
