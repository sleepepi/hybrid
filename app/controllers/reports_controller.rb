class ReportsController < ApplicationController
  before_filter :authenticate_user!

  # This retrieves the entire dataset
  def get_csv
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = @query.reports.find_by_id(params[:id]) if @query
    if @query and @report
      view_concept_ids = Concept.current.with_concept_type(['file locator']).with_source(@query.sources.collect{|s| s.id}).collect{|c| c.id} | @report.concepts.collect{|c| c.id}
      view_concept_values = @query.view_concept_values(current_user, @query.sources, view_concept_ids, @query.query_concepts, [], ["download dataset", "download limited dataset"])
      @graph_values = view_concept_values[:result]
      @error = view_concept_values[:error]

      csv_string = CSV.generate do |csv|
        @graph_values.each do |row|
          csv << row
        end
      end

      send_data csv_string,
                type: 'text/csv; charset=iso-8859-1; header=present',
                disposition: "attachment; filename=\"#{@report.name.gsub(/[^\w]/, '')}_report_#{@report.id}_#{Time.now.strftime("%Y.%m.%d %Ih%M %p")}.csv\""
    else
      render nothing: true
    end
  end

  # This retrieves the created report table
  def get_table
    @report = current_user.reports.find_by_id(params[:id])
    if @report

      result_hash = @report.finalize_report_table(current_user, false)

      if result_hash[:error].blank?
        csv_string = CSV.generate do |csv|
          result_hash[:result].each do |row|
            csv << row
          end
        end

        send_data csv_string,
                  type: 'text/csv; charset=iso-8859-1; header=present',
                  disposition: "attachment; filename=\"#{@report.name.gsub(/[^\w]/, '')}_report_#{@report.id}_summary_#{Time.now.strftime("%Y.%m.%d %Ih%M %p")}.csv\""
      else
        render nothing: true
      end
    else
      render nothing: true
    end
  end

  def report_table
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = @query.reports.find_by_id(params[:id]) if @query
    render nothing: true unless @query and @report
  end

  def edit
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = @query.reports.find_by_id(params[:id]) if @query
    if @query and @report
      params[:add_report_id] = @report.id
      render 'edit'
    else
      render nothing: true
    end
  end

  def create
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @query and @report = @query.reports.create(user_id: current_user.id, name: params[:report][:name], is_dataset: params[:is_dataset])
      @element_id = (params[:is_dataset] == 'true') ? "dataset_tabs-#{@query.true_datasets.size + 1}" : "report_tabs-#{@query.true_reports.size + 1}"

      if template_report = current_user.reports.find_by_id(params[:template_report_id])
        template_report.report_concepts.each do |report_concept|
          @report.report_concepts << ReportConcept.create(report_concept.dup.attributes)
        end
      end

      if params[:is_dataset] == 'true'
        render "datasets"
      else
        render "reports"
      end
    else
      render nothing: true
    end
  end

  def destroy
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = @query.reports.find_by_id(params[:id]) if @query
    if @query and @report
      @report.destroy
      if @report.is_dataset?
        render "datasets"
      else
        render "reports"
      end
    else
      render nothing: true
    end
  end

  def edit_name
    @report = current_user.reports.find_by_id(params[:id])
    @query = current_user.all_queries.find_by_id(params[:query_id])
    render nothing: true unless @report and @query
  end

  def save_name
    @report = current_user.reports.find_by_id(params[:id])
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @report and @query
      @report.update_attribute :name, params[:report][:name]
    else
      render nothing: true
    end
  end

  def reorder
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @report = current_user.reports.find_by_id(params[:id])
    if @query and @report
      row_report_concept_ids = params[:rows].to_s.gsub('report_concept_', '').split(',')
      column_report_concept_ids = params[:columns].to_s.gsub('report_concept_', '').split(',')
      @report.reorder(column_report_concept_ids, row_report_concept_ids)
      render 'report_table'
    else
      render nothing: true
    end
  end

end
