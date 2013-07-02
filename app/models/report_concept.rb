class ReportConcept < ActiveRecord::Base
  STATISTIC = ["all", "avg", "min", "max"].collect{|i| [i,i]}

  # Model Validation
  validates_presence_of :report_id, :variable_id, :position

  # Model Relationships
  belongs_to :report
  belongs_to :variable
  belongs_to :source

  def source
    if self.source_id and selected_source = Source.find_by_id(self.source_id)
      selected_source
    else
      self.variable.sources.first
    end
  end

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'report_id', 'created_at', 'updated_at'].include?(key.to_s)}
  end

end
