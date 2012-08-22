class QuerySource < ActiveRecord::Base
  belongs_to :query, touch: true
  belongs_to :source
end
