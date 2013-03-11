class QueriesController < ApplicationController
  before_action :authenticate_user!

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
        @sql_conditions = ''
        @overall_totals[nil] = '&lsaquo;&Oslash;&rsaquo;'.html_safe
        @overall_errors[nil] = 'No Data Sources Selected';
      else
        sub_totals = []

        sources.each do |source|
          if source.user_has_action?(current_user, 'get count') or current_user.all_sources.include?(source)
            sub_totals << query.record_count_only_with_sub_totals(current_user, source, query_concepts)
          else
            sub_totals << {result: [[nil, 0]], errors: [[nil, "No permissions to get counts for #{source.name}"]] }
          end
        end

        @sql_conditions = sub_totals.collect{|st| st[:sql_conditions]}

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

  def edit_name
    @query = current_user.all_queries.find_by_id(params[:id])
    render nothing: true unless @query
  end

  def save_name
    @query = current_user.all_queries.find_by_id(params[:id])
    if @query
      @query.update_attributes name: params[:query][:name]
    else
      render nothing: true
    end
  end

  def undo
    @query = current_user.all_queries.find_by_id(params[:id])
    if @query
      @query.undo!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def redo
    @query = current_user.all_queries.find_by_id(params[:id])
    if @query
      @query.redo!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def index
    # current_user.update_column :queries_per_page, params[:queries_per_page].to_i if params[:queries_per_page].to_i >= 5 and params[:queries_per_page].to_i <= 20
    query_scope = current_user.all_queries

    @search_terms = params[:search].to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| query_scope = query_scope.search(search_term) }

    @order = scrub_order(Query, params[:order], 'queries.created_at DESC')
    query_scope = query_scope.order(@order)

    @queries = query_scope.page(params[:page]).per(20) # current_user.queries_per_page)
  end


  def show
    @query = current_user.all_queries.find_by_id(params[:id])
    @query = current_user.all_queries.find_by_id(current_user.current_query_id) unless @query
    @query = current_user.queries.create(name: "#{current_user.last_name} #{Time.now.strftime("%Y.%m.%d %l:%M %p")}") unless @query

    current_user.update_column :current_query_id, @query.id
  end

  def new
    @query = current_user.queries.create(name: "#{current_user.last_name} #{Time.now.strftime("%Y.%m.%d %l:%M %p")}")
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

  # # GET /queries/1/edit
  # def edit
  #   @query = Query.find(params[:id])
  # end
  #
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
    @query = current_user.all_queries.find_by_id(params[:id])
    @query.destroy if @query
    redirect_to queries_path
  end
end
