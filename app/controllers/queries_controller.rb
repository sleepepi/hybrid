class QueriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_query,               only: [ :autocomplete, :destroy, :variables_popup, :open_folder, :edit, :update, :undo, :redo ]
  before_action :redirect_without_query,  only: [ :autocomplete, :destroy, :variables_popup, :open_folder, :edit, :update, :undo, :redo ]

  # GET /queries/1/variable_popup.js
  def variables_popup

  end

  # GET /queries/1/open_folder.js
  def open_folder

  end

  def autocomplete
    @query = current_user.queries.find_by_id(params[:id])

    variable_scope = Variable.current.search(params[:search]).where( dictionary_id: @query.sources.collect{|s| s.all_linked_sources_and_self}.flatten.uniq.collect{|s| s.variables.pluck(:dictionary_id).uniq}.flatten.uniq )

    @variables = variable_scope.page(params[:page]).per(10)
      # @order = scrub_order(Concept, params[:order], "concepts.search_name")
      # concept_scope = concept_scope.order("(concepts.folder IS NULL or concepts.folder = '') ASC, concepts.folder ASC, " + @order)
      # @concepts = concept_scope.page(params[:page]).per(10)

    render json: @variables.group_by{|v| v.folder}.collect{|folder, variables| { text: folder, commonly_used: true, children: variables.collect{|v| { id: v.id, text: v.display_name, commonly_used: v.commonly_used }}}}
  end

  # Get Count
  def total_records_count
    query = current_user.all_queries.find_by_id(params[:id])
    if query
      query_concepts = query.query_concepts
      sources = query.sources

      total_records_found = 0
      @overall_totals = {}
      @overall_errors = {}

      if sources.size == 0
        @sql_conditions = []
        @overall_totals[nil] = 0
        @overall_errors[nil] = 'No Data Sources Selected'
      else
        sub_totals = []

        sources.each do |source|
          if source.user_has_action?(current_user, 'get count') or current_user.all_sources.include?(source)
            sub_totals << query.record_count_only_with_sub_totals_using_resolvers(current_user, source, query_concepts)
          else
            sub_totals << { result: [[nil, 0]], errors: [[nil, "No permissions to get counts for #{source.name}"]] }
          end
        end

        @sql_conditions = sub_totals.collect{|st| st[:sql_conditions]}.flatten

        sub_totals.each do |sub_total_hash|
          sub_total = sub_total_hash[:result]
          sub_total_error = sub_total_hash[:errors]

          sub_total.each do |grouping, total|
            @overall_totals[grouping] = @overall_totals[grouping].to_i + total.to_i
          end

          sub_total_error.each do |grouping, total|
            @overall_errors[grouping] = [@overall_errors[grouping], "#{total}"].select{|i| not i.blank?}.join(', ')
          end
        end
      end
    else
      render nothing: true
    end
  end

  def reorder
    @query = current_user.all_queries.find_by_id(params[:id])
    if @query
      query_concept_ids = params[:order].to_s.gsub('query_concept_', '').split(',').select{|i| not i.blank?}
      @query.reorder(query_concept_ids)
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def data_files
    @file_type = FileType.find_by_id(params[:file_type_id])
    @query = current_user.queries.find_by_id(params[:id])
    render nothing: true unless @query
  end

  def load_file_type
    @file_type = FileType.find_by_id(params[:file_type_id])
    @query = current_user.queries.find_by_id(params[:id])
    render nothing: true unless @query
  end

  # GET /queries/1/edit.js
  def edit
  end

  # POST /queries/1.js
  def update
    @query.reload unless @query.update query_params
    render 'show'
  end

  def undo
    @query.undo!
    render 'query_concepts/query_concepts'
  end

  def redo
    @query.redo!
    render 'query_concepts/query_concepts'
  end

  def index
    @order = scrub_order(Query, params[:order], 'queries.created_at DESC')
    @queries = current_user.all_queries.search(params[:search]).order(@order).page(params[:page]).per(20)
  end

  def show
    @query = current_user.all_queries.find_by_id(params[:id])
    @query = current_user.all_queries.find_by_id(current_user.current_query_id) unless @query
    @query = current_user.queries.create(name: "#{current_user.last_name} Search ##{current_user.queries.count+1}") unless @query

    current_user.update_column :current_query_id, @query.id
  end

  def new
    @query = current_user.queries.create(name: "#{current_user.last_name}  Search ##{current_user.queries.count+1}")
    current_user.update_column :current_query_id, @query.id
    redirect_to root_path, notice: "Created search #{@query.name}"
  end

  def copy
    @original_query = current_user.all_queries.find_by_id(params[:id])
    if @original_query
      @query = @original_query.copy
      current_user.update_column :current_query_id, @query.id
      redirect_to root_path, notice: "Copied search #{@original_query.name}"
    else
      redirect_to root_path, alert: "You do not have access to that query"
    end
  end

  # # POST /queries
  # # POST /queries.xml
  # def create
  #   @query = Query.new(params[:query])
  #
  #   respond_to do |format|
  #     if @query.save
  #       format.html { redirect_to(@query, notice: 'Query was successfully created.') }
  #       format.xml  { render xml: @query, status: :created, location: @query }
  #     else
  #       format.html { render action: "new" }
  #       format.xml  { render xml: @query.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # # PUT /queries/1
  # # PUT /queries/1.xml
  # def update
  #   @query = Query.find(params[:id])
  #
  #   respond_to do |format|
  #     if @query.update_attributes(params[:query])
  #       format.html { redirect_to(@query, notice: 'Query was successfully updated.') }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render action: "edit" }
  #       format.xml  { render xml: @query.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  def destroy
    @query.destroy
    redirect_to queries_path
  end

  private

    def set_query
      super(:id)
    end

    def query_params
      params.require(:query).permit(
        :name
      )
    end


end
