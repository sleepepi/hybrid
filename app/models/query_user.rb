class QueryUser < ActiveRecord::Base
  belongs_to :search
  belongs_to :user
end
