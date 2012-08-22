class AddReportDatasetFlag < ActiveRecord::Migration
  def up
    add_column :reports, :is_dataset, :boolean, :default => true, :null => false
  end

  def down
    remove_column :reports, :is_dataset
  end
end
