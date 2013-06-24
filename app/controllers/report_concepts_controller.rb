class ReportConceptsController < ApplicationController
  before_action :authenticate_user!

  def create
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = @query.reports.find_by_id(params[:report_id]) if @query
    concept = Concept.current.find_by_id(params[:concept_id])

    if @query and concept and @report
      @report.report_concepts << @report.report_concepts.create(concept_id: concept.id, position: @report.report_concepts.size + 1) unless @report.concepts.include?(concept)
      @report.reload
      render 'report_concepts/report_concepts'
    else
      render nothing: true
    end
  end

  def destroy
    @report_concept = ReportConcept.find_by_id(params[:id])
    @report = @report_concept.report if @report_concept
    @query = @report.query if @report
    if @report_concept and @report and @query and current_user.all_queries.include?(@query)
      @report.report_concepts.select{|rc| rc.position > @report_concept.position}.each{|rc| rc.update_column :position, rc.position - 1}
      @report_concept.destroy
      @report.reload
      render 'report_concepts/report_concepts'
    else
      render nothing: true
    end
  end

  def update
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report_concept = ReportConcept.find_by_id(params[:id])
    @report = current_user.reports.find_by_id(@report_concept.report_id) if @report_concept
    if @query and @report_concept and @report
      @report_concept.update( statistic: params[:report_concept][:statistic], source_id: params[:report_concept][:source_id] )
      render 'reports/report_table'
    else
      render nothing: true
    end
  end
end
