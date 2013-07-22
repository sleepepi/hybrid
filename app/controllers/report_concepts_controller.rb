class ReportConceptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search,                      only: [ :create, :update, :destroy ]
  before_action :redirect_without_search,         only: [ :create, :update, :destroy ]
  before_action :set_report,                      only: [ :create, :update, :destroy ]
  before_action :redirect_without_report,         only: [ :create, :update, :destroy ]
  before_action :set_report_concept,              only: [ :update, :destroy ]
  before_action :redirect_without_report_concept, only: [ :update, :destroy ]

  def create
    variable = Variable.current.find_by_id(params[:variable_id])

    if variable
      @report.report_concepts << @report.report_concepts.create( variable_id: variable.id, position: @report.report_concepts.size + 1) unless @report.variables.include?(variable)
      @report.reload
    end
    render 'report_concepts/report_concepts'
  end

  def update
    @report_concept.update( statistic: params[:report_concept][:statistic], source_id: params[:report_concept][:source_id] )
    render 'reports/report_table'
  end

  def destroy
    @report.report_concepts.select{|rc| rc.position > @report_concept.position}.each{|rc| rc.update_column :position, rc.position - 1}
    @report_concept.destroy
    @report.reload
    render 'report_concepts/report_concepts'
  end

  private

    def set_report
      @report = @search.reports.find_by_id(params[:report_id])
    end

    def redirect_without_report
      empty_response_or_root_path unless @report
    end

    def set_report_concept
      @report_concept = @report.report_concepts.find_by_id(params[:id])
    end

    def redirect_without_report_concept
      empty_response_or_root_path unless @report_concept
    end
end
