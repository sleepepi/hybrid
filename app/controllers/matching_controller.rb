class MatchingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_queries, only: [ :matching, :add_variable, :add_criteria ]

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
        load_criteria_concepts
        load_extra_concepts
      end
    end
  end

  def add_variable
    load_extra_concepts
  end

  def add_criteria
    load_criteria_concepts
  end

  private

    def set_queries
      @cases = current_user.all_queries.find_by_id(params[:cases_id])
      @controls = current_user.all_queries.find_by_id(params[:controls_id])
      @controls_per_case = (params[:controls_per_case].to_i <= 4 and params[:controls_per_case].to_i >= 1) ? params[:controls_per_case].to_i : 1
      @sources = (@cases ? @cases.sources.to_a : []) & (@controls ? @controls.sources.to_a : [])
    end

    def load_criteria_concepts
      concepts = []
      @sources.each do |s|
        concepts += (concepts + s.concepts.where(concept_type: 'categorical').collect{|c| [c.display_name, c.id]}).uniq
      end
      @concepts = concepts.sort{|a,b| a[0].to_s <=> b[0].to_s}
    end

    def load_extra_concepts
      all_concepts = []
      @sources.each do |s|
        all_concepts += (all_concepts + s.concepts.where("folder != '' and folder IS NOT NULL").collect{|c| [c.display_name, c.id]}).uniq
      end
      @all_concepts = all_concepts.sort{|a,b| a[0].to_s <=> b[0].to_s}
    end

    def create_matches(include_extra)
      @matches = []
      cases_matrix = []
      controls_matrix = []

      if @cases and @controls
        @common_identifier = (@cases.sources.collect{|s| s.concepts.where(concept_type: 'identifier')}.flatten.uniq & @controls.sources.collect{|s| s.concepts.where(concept_type: 'identifier')}.flatten.uniq).first

        all_criteria = (params[:criteria_ids] || []).compact.uniq
        concept_ids = (params[:variable_ids] || []).compact.uniq - all_criteria

        @matching_concepts = (@cases.sources.collect{|s| s.concepts.where(id: all_criteria)}.flatten.uniq & @controls.sources.collect{|s| s.concepts.where(id: all_criteria)}.flatten.uniq)
        @extra_concepts = (include_extra ? (@cases.sources.collect{|s| s.concepts.where(id: concept_ids)}.flatten.uniq & @controls.sources.collect{|s| s.concepts.where(id: concept_ids)}.flatten.uniq) : [])

        concepts = [@common_identifier] + @matching_concepts + @extra_concepts
        cases_matrix = @cases.view_concept_values(current_user, @cases.sources, concepts, ["view data distribution", "view limited data distribution"], [] )
        controls_matrix = @controls.view_concept_values(current_user, @controls.sources, concepts, ["view data distribution", "view limited data distribution"], [] )

        extra_start_index = @matching_concepts.size + 1

        @overall_criteria = @matching_concepts.collect(&:human_name)
        @overall_extra = @extra_concepts.collect(&:human_name)


        cases_matrix.each do |case_info|
          id = case_info[0]
          # Select matching IDs
          criteria = case_info[1..@matching_concepts.size]

          case_extra = case_info[extra_start_index..-1]

          matching_ids = controls_matrix.select{|control| control[1..@matching_concepts.size] == criteria}.collect{|control| control[0]}[0..(@controls_per_case - 1)]

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
