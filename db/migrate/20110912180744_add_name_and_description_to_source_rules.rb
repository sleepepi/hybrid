class AddNameAndDescriptionToSourceRules < ActiveRecord::Migration
  def change
    add_column :source_rules, :name, :string
    add_column :source_rules, :description, :text
  end
end
