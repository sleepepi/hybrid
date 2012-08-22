class SourceJoin < ActiveRecord::Base

  # Named Scopes
  scope :current, conditions: { }
  scope :search, lambda { |*args| { conditions: [ 'LOWER(from_table) LIKE ? or LOWER(from_column) LIKE ? or LOWER(to_table) LIKE ? or LOWER(to_column) LIKE ?', '%' + args.first.downcase.split(' ').join('%') + '%', '%' + args.first.downcase.split(' ').join('%') + '%', '%' + args.first.downcase.split(' ').join('%') + '%', '%' + args.first.downcase.split(' ').join('%') + '%' ] } }
  scope :with_source, lambda { |*args| { conditions: [ 'source_id IN (?) or source_to_id IN (?)', args.first, args.first ] } }

  belongs_to :source
  belongs_to :source_to, class_name: 'Source', foreign_key: 'source_to_id'

  # Model Validation
  validates_presence_of :source_id, :from_table, :from_column, :to_table, :to_column

  scope :with_from_table, lambda { |*args| { conditions: ["from_table IN (?) or 'all' IN (?)", args.first, args.first]} }
  scope :with_to_table, lambda { |*args| { conditions: ["to_table IN (?) or 'all' IN (?)", args.first, args.first]} }
  scope :with_table, lambda { |*args| { conditions: ["from_table IN (?) or to_table IN (?) or 'all' IN (?)", args.first, args.first, args.first]} }

  def name
    "ID ##{self.id}"
  end
end
