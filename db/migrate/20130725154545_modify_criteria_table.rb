class ModifyCriteriaTable < ActiveRecord::Migration
  def change
    remove_column :criteria, :grouping, :integer
    remove_column :criteria, :group_negated, :boolean, null: false, default: false
    remove_column :criteria, :external_key, :string

    add_index :criteria, :variable_id
    add_index :criteria, :mapping_id
  end
end
