class ReportsController < ApplicationController
  before_action :authenticate_user!

  # This retrieves the entire dataset
  def get_csv
    @search = current_user.all_searches.find_by_id(params[:search_id])
    @report = @search.reports.find_by_id(params[:id]) if @search
    if @search and @report
      csv_string = CSV.generate do |csv|
        csv << @report.report_concepts.collect{|rc| rc.variable.display_name}
        @search.view_concept_values(current_user, @report.report_concepts, ["download dataset", "download limited dataset"]).each do |row|
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
    @search = current_user.all_searches.find_by_id(params[:search_id])
    @report = @search.reports.find_by_id(params[:id]) if @search
    render nothing: true unless @search and @report
  end

  def edit
    @search = current_user.all_searches.find_by_id(params[:search_id])
    @report = @search.reports.find_by_id(params[:id]) if @search
    if @search and @report
      params[:add_report_id] = @report.id
      render 'edit'
    else
      render nothing: true
    end
  end

  def create
    @search = current_user.all_searches.find_by_id(params[:search_id])
    if @search and @report = @search.reports.create(user_id: current_user.id, name: params[:report][:name], is_dataset: params[:is_dataset])
      @element_id = (params[:is_dataset] == 'true') ? "dataset_tabs-#{@search.true_datasets.size + 1}" : "report_tabs-#{@search.true_reports.size + 1}"

      if template_report = current_user.reports.find_by_id(params[:template_report_id])
        template_report.report_concepts.each do |report_concept|
          @report.report_concepts << ReportConcept.create(report_concept.copyable_attributes)
        end
      end

      render "reports"
    else
      render nothing: true
    end
  end

  def destroy
    @search = current_user.all_searches.find_by_id(params[:search_id])
    @report = @search.reports.find_by_id(params[:id]) if @search
    if @search and @report
      @report.destroy
      render "reports"
    else
      render nothing: true
    end
  end

  def edit_name
    @report = current_user.reports.find_by_id(params[:id])
    @search = current_user.all_searches.find_by_id(params[:search_id])
    render nothing: true unless @report and @search
  end

  def save_name
    @report = current_user.reports.find_by_id(params[:id])
    @search = current_user.all_searches.find_by_id(params[:search_id])
    if @report and @search
      @report.update_attributes name: params[:report][:name]
    else
      render nothing: true
    end
  end

  def reorder
    @search = current_user.all_searches.find_by_id(params[:search_id])
    @report = current_user.reports.find_by_id(params[:id])
    if @search and @report
      row_report_concept_ids = params[:rows].to_s.gsub('report_concept_', '').split(',')
      column_report_concept_ids = params[:columns].to_s.gsub('report_concept_', '').split(',')
      @report.reorder(column_report_concept_ids, row_report_concept_ids)
      render 'report_table'
    else
      render nothing: true
    end
  end

end
