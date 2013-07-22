class MatchingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_searches, only: [ :matching, :add_variable, :add_criteria ]

  def matching
    respond_to do |format|
      format.csv do
        create_matches(true)
        send_data csv_string, type: 'text/csv; charset=iso-8859-1; header=present', disposition: "attachment; filename=\"Matching #{Time.now.strftime("%Y.%m.%d %Ih%M %p")}.csv\""
      end
      format.js do
        create_matches(true) # (false)
      end
      format.html do
        load_criteria_variables
        load_extra_variables
      end
    end
  end

  def add_variable
    load_extra_variables
  end

  def add_criteria
    load_criteria_variables
  end

  private

    def set_searches
      @cases = current_user.all_searches.find_by_id(params[:cases_id])
      @controls = current_user.all_searches.find_by_id(params[:controls_id])
      @controls_per_case = (params[:controls_per_case].to_i <= 4 and params[:controls_per_case].to_i >= 1) ? params[:controls_per_case].to_i : 1
      @sources = (@cases ? @cases.sources.to_a : []) & (@controls ? @controls.sources.to_a : [])
    end

    def load_criteria_variables
      variables = []
      @sources.each do |s|
        variables += (variables + s.variables.where( variable_type: 'choices' ).collect{|v| [v.display_name, v.id]}).uniq
      end
      @variables = variables.sort{|a,b| a[0].to_s <=> b[0].to_s}
    end

    def load_extra_variables
      all_variables = []
      @sources.each do |s|
        all_variables += (all_variables + s.variables.collect{|v| [v.display_name, v.id]}).uniq
      end
      @all_variables = all_variables.sort{|a,b| a[0].to_s <=> b[0].to_s}
    end

    def create_matches(include_extra)
      @matches = []
      cases_matrix = []
      controls_matrix = []

      if @cases and @controls
        @common_identifier = (@cases.sources.collect{|s| s.variables.where( variable_type: 'identifier' )}.flatten.uniq & @controls.sources.collect{|s| s.variables.where( variable_type: 'identifier' )}.flatten.uniq).first

        all_criteria = (params[:criteria_ids] || []).compact.uniq
        variable_ids = (params[:variable_ids] || []).compact.uniq - all_criteria

        @matching_variables = (@cases.sources.collect{|s| s.variables.where(id: all_criteria)}.flatten.uniq & @controls.sources.collect{|s| s.variables.where(id: all_criteria)}.flatten.uniq)
        @extra_variables = (include_extra ? (@cases.sources.collect{|s| s.variables.where(id: variable_ids)}.flatten.uniq & @controls.sources.collect{|s| s.variables.where(id: variable_ids)}.flatten.uniq) : [])

        report_variables = []
        ([@common_identifier] + @matching_variables + @extra_variables).compact.each do |variable|
          report_variables << ReportConcept.new( variable_id: variable.id )
        end
        cases_matrix = @cases.view_concept_values( current_user, report_variables )
        controls_matrix = @controls.view_concept_values( current_user, report_variables )

        extra_start_index = @matching_variables.size + 1

        @overall_criteria = @matching_variables.collect(&:display_name)
        @overall_extra = @extra_variables.collect(&:display_name)


        cases_matrix.each do |case_info|
          id = case_info[0]
          # Select matching IDs
          criteria = case_info[1..@matching_variables.size]

          case_extra = case_info[extra_start_index..-1]

          matching_ids = controls_matrix.select{|control| control[1..@matching_variables.size] == criteria}.collect{|control| control[0]}[0..(@controls_per_case - 1)]

          extra = []

          matching_ids.each do |matching_id|
            extra << controls_matrix.select{|control| control[0] == matching_id }.first[extra_start_index..-1]
          end

          # Remove matching IDs from controls_matrix so they aren't reused
          controls_matrix.delete_if{|control| matching_ids.include?(control[0])}

          @matches << { id: id, case_extra: case_extra, matching_ids: matching_ids, criteria: criteria, extra: extra }
        end
      end
    end

    def csv_string
      csv_string = CSV.generate do |csv|
        # header row
        csv << ["identifier", "type", "matched_identifier"] + @overall_criteria + @overall_extra
        @matches.each do |match|
          csv << [match[:id], 'case', nil] + match[:criteria] + match[:case_extra]
          match[:matching_ids].each_with_index do |control_id, index|
            csv << [control_id, 'control', match[:id]] + match[:criteria] + match[:extra][index]
          end
        end
      end
      csv_string
    end

end
