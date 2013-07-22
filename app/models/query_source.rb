class QuerySource < ActiveRecord::Base
  belongs_to :search, touch: true
  belongs_to :source
end
