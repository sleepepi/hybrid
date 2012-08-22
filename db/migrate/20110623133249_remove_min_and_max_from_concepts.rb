class RemoveMinAndMaxFromConcepts < ActiveRecord::Migration
  def self.up
    remove_column :concepts, :minimum
    remove_column :concepts, :maximum
  end

  def self.down
    add_column :concepts, :minimum, :integer
    add_column :concepts, :maximum, :integer
  end
end
