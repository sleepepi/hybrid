class ConceptsController < ApplicationController
  before_action :authenticate_user!

  def info
    @concept = Concept.find_by_id(params[:id])
    @query = current_user.all_queries.find_by_id(params[:query_id])

    if @concept and @concept.mappings.size > 0
      chart_params = {}
      width = "100%"
      if @concept.continuous? or @concept.date?
        chart_params = { title: @concept.human_name, width: width, height: "300px", units: @concept.human_units, legend: 'none' }
      elsif @concept.categorical? or @concept.boolean?
        chart_params = { title: @concept.human_name, width: width, height: "250px" }
      end

      result_hash = @concept.graph_values(current_user, chart_params)
      @values = result_hash[:values]
      @categories = result_hash[:categories]
      @chart_type = result_hash[:chart_type]
      @chart_element_id = result_hash[:chart_element_id]
      @stats = result_hash[:stats]
      @defaults = result_hash[:defaults]

      @mapping = 1
    end

    render nothing: true unless @concept
  end

  def index
    @query = current_user.queries.find_by_id(params[:query_id])

    concept_scope = Concept.current.with_concept_type(params[:concept_type] || 'all')
    search_string = (params[:search] || params[:term] || params[:concept_search_term]).to_s.strip

    @search_terms = search_string.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| concept_scope = concept_scope.search(search_term) }

    if params[:autocomplete] == 'true'
      concept_scope = concept_scope.with_source(@query.sources.collect{|s| s.all_linked_sources_and_self}.flatten.uniq.collect{|s| s.id}) if @query

      @order = scrub_order(Concept, params[:order], "concepts.search_name")
      concept_scope = concept_scope.order("(concepts.folder IS NULL or concepts.folder = '') ASC, concepts.folder ASC, " + @order)
      @concepts = concept_scope.page(params[:page]).per(10)

      @external_concepts = []
      if @query and not search_string.blank?
        @query.sources.each do |source|
          external_concepts_hash = source.external_concepts(current_user, '', search_string)
          if external_concepts_hash[:error].blank?
            @external_concepts = @external_concepts | external_concepts_hash[:result]
          end
        end
      end

      render json: @concepts.group_by{|c| c.folder}.collect{|folder, concepts| { text: folder, commonly_used: true, children: concepts.collect{|c| { id: c.id, text: c.human_name, commonly_used: c.commonly_used }}}}
    else
      @order = scrub_order(Concept, params[:order], "concepts.search_name")
      concept_scope = concept_scope.with_dictionary(params[:dictionary_id].blank? ? 'all' : params[:dictionary_id]).order(@order)
      @concepts = concept_scope.page(params[:page]).per(20)
      @dictionary = Dictionary.available.find_by_id(params[:dictionary_id])
    end
  end

  def search_folder
    params['concept_search'] = params['search'] if params['concept_search'].blank?
    @query = current_user.queries.find_by_id(params[:query_id])
    @query = current_user.queries.new if @query.blank?
    render 'popup' if params[:popup] == 'true'
  end

  def open_folder
    @query = current_user.queries.find_by_id(params[:query_id])
    @folder = params[:folder_name]
    @r = Regexp.new("^#{params[:prefix].to_s.gsub('\\','\\\\\\\\')}:")
    @query = current_user.queries.new if @query.blank?
    render nothing: true unless @query
  end

  def info_external
    @concept = Concept.new(short_name: params[:short_name], totalnum: params[:totalnum], key: params[:key], source_id: params[:source_id])
    @query_concept = QueryConcept.new(external_key: params[:key], source_id: params[:source_id])
    @query = current_user.all_queries.find_by_id(params[:query_id])

    @mapping = nil

    render 'info'
  end

  def show
    @concept = Concept.find_by_id(params[:id])
    unless @concept
      redirect_to concepts_path
    end
  end

end
