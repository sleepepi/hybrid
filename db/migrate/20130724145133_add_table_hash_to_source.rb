class AddTableHashToSource < ActiveRecord::Migration
  def change
    add_column :sources, :table_hash, :text
  end
end
