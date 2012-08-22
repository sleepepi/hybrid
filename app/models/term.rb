class Term < ActiveRecord::Base
  belongs_to :concept
  
  def update_search_name!
    self.update_attribute :search_name, self.name.gsub(/[^\w']/, ' ').titleize.downcase
  end
end
