class ConceptsController < ApplicationController
  before_filter :authenticate_user!

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
    # current_user.update_column :users_per_page, params[:users_per_page].to_i if params[:users_per_page].to_i >= 10 and params[:users_per_page].to_i <= 200
    concept_scope = Concept.current
    @query = current_user.queries.find_by_id(params[:query_id])

    # @first_terms = params[:term].to_s.split(',')[0..-2]
    # @search_terms = params[:term].to_s.split(',').last.strip.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')

    concept_scope = concept_scope.with_concept_type(params[:concept_type] || 'all')
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

      render 'autocomplete'
    else
      concept_scope = concept_scope.with_dictionary(params[:dictionary_id].blank? ? 'all' : params[:dictionary_id]).order(@order)
      @concepts = concept_scope.page(params[:page]).per(20) #(current_user.concepts_per_page)
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
    @concept = Concept.new(name: params[:name], totalnum: params[:totalnum], key: params[:key], source_id: params[:source_id])
    @query_concept = QueryConcept.new(external_key: params[:key], source_id: params[:source_id])
    @query = current_user.all_queries.find_by_id(params[:query_id])

    @mapping = nil

    render 'info'
  end

  # # GET /concepts
  # # GET /concepts.xml
  # def index
  #   @concepts = Concept.all
  #
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render xml: @concepts }
  #   end
  # end

  def show
    @concept = Concept.find_by_id(params[:id])
    unless @concept
      redirect_to concepts_path
    end
  end

  # # GET /concepts/new
  # # GET /concepts/new.xml
  # def new
  #   @concept = Concept.new
  #
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render xml: @concept }
  #   end
  # end
  #
  # # GET /concepts/1/edit
  # def edit
  #   @concept = Concept.find(params[:id])
  # end
  #
  # # POST /concepts
  # # POST /concepts.xml
  # def create
  #   @concept = Concept.new(params[:concept])
  #
  #   respond_to do |format|
  #     if @concept.save
  #       format.html { redirect_to(@concept, notice: 'Concept was successfully created.') }
  #       format.xml  { render xml: @concept, status: :created, location: @concept }
  #     else
  #       format.html { render action: "new" }
  #       format.xml  { render xml: @concept.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # # PUT /concepts/1
  # # PUT /concepts/1.xml
  # def update
  #   @concept = Concept.find(params[:id])
  #
  #   respond_to do |format|
  #     if @concept.update_attributes(params[:concept])
  #       format.html { redirect_to(@concept, notice: 'Concept was successfully updated.') }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render action: "edit" }
  #       format.xml  { render xml: @concept.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # # DELETE /concepts/1
  # # DELETE /concepts/1.xml
  # def destroy
  #   @concept = Concept.find(params[:id])
  #   @concept.destroy
  #
  #   respond_to do |format|
  #     format.html { redirect_to(concepts_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
