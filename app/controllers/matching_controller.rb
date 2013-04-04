class MatchingController < ApplicationController
  before_action :authenticate_user!

  def matching
    @cases = current_user.all_queries.find_by_id(params[:cases_id])
    @controls = current_user.all_queries.find_by_id(params[:controls_id])
    @controls_per_case = (params[:controls_per_case].to_i <= 4 and params[:controls_per_case].to_i >= 1) ? params[:controls_per_case].to_i : 1
    @sources = (@cases ? @cases.sources.to_a : []) & (@controls ? @controls.sources.to_a : [])
    concepts = []
    @sources.each do |s|
      concepts += (concepts + s.concepts.where(concept_type: 'categorical').collect{|c| [c.display_name, c.id]}).uniq
    end
    @concepts = concepts.sort{|a,b| a[0].to_s <=> b[0].to_s}
  end

end
