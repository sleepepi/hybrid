class Term < ActiveRecord::Base

  # Model Relationships
  belongs_to :concept

  # Term Methods

  def update_search_name!
    self.update_column :search_name, self.name.to_s.gsub(/[^\w']/, ' ').titleize.downcase unless self.new_record?
  end
end
