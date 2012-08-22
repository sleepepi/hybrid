class CreateSourceFileTypes < ActiveRecord::Migration
  def change
    create_table :source_file_types do |t|
      t.integer :source_id
      t.integer :file_type_id

      t.timestamps
    end
  end
end
