class AddRightOperatorToQueryConcept < ActiveRecord::Migration
  def self.up
    add_column :query_concepts, :right_operator, :string, :null => false, :default => 'and'
    add_column :query_concepts, :left_brackets, :integer, :null => false, :default => 0
    add_column :query_concepts, :right_brackets, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :query_concepts, :right_operator
    remove_column :query_concepts, :left_brackets
    remove_column :query_concepts, :right_brackets
  end
end
