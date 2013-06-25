class RenameSourceRuleToRule < ActiveRecord::Migration
  def change
    rename_table :source_rules, :rules
  end
end
