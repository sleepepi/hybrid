class SourcesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_source, only: [ :destroy ]
  before_action :set_source_with_edit_data_source_connection_information, only: [ :edit, :update ]
  before_action :set_source_with_edit_data_source_mappings, only: [ :auto_map, :remove_all_mappings ]
  before_action :set_source_with_view_or_edit_data_source_mappings, only: [ :table_columns ]
  before_action :redirect_without_source, only: [ :destroy, :edit, :update, :auto_map, :remove_all_mappings ]

  def download_file
    @source = current_user.all_sources.find_by_id(params[:id])
    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "download files")

    if @source
      result_hash = Aqueduct::Builder.repository(@source, current_user).get_file(params[:file_locator], params[:file_type])
      file_path = result_hash[:file_path]
      if result_hash[:error].blank? and File.exists?(file_path.to_s)
        send_file file_path, disposition:'attachment'
      else
        render text: "File not found on server..."
      end
    else
      render nothing: true
    end
  end

  def auto_map
    if params[:table].blank?
      result_hash = @source.tables(current_user)
      tables = result_hash[:result] || []
    else
      tables = [params[:table]]
    end

    tables.each do |table|

      result_hash = @source.table_columns(current_user, table)
      @columns = result_hash[:result]
      @error = result_hash[:error]
      current_time = Time.now

      @columns.each do |column_hash|
        mapping = @source.mappings.find_by_table_and_column_and_column_value(table, column_hash[:column], nil)
        concepts = Concept.with_dictionary(params[:dictionary_id]).searchable.exactly(column_hash[:column].to_s.gsub(/[^\w]/, ' ').titleize.downcase, column_hash[:column].to_s.gsub(/[^\w]/, ' ').downcase)
        c = concepts.first
        if concepts.size == 1 and c
          mapping = @source.mappings.find_or_create_by_table_and_column_and_column_value(table, column_hash[:column], nil) unless mapping
          mapping.automap(current_user, c, column_hash)
        end
      end

    end

    table_div_name = tables.first.to_s.gsub(/[^\w\-]/, '_') # TODO: Remove or implement count update after automap for table
    all_columns = @columns.collect{|a| a[:column]}

    params[:page] = 1 if params[:page].blank?
    params[:table] = tables.first.to_s
    result_hash = @source.table_columns(current_user, params[:table], params[:page].to_i, 20, params[:filter_unmapped] == '1')
    @columns = result_hash[:result]
    @max_pages = result_hash[:max_pages]
    @error = result_hash[:error]
    params[:page] = result_hash[:page] unless result_hash[:page].blank?

    render 'table_columns'
  end

  def remove_all_mappings
    @source.mappings.destroy_all
    redirect_to @source
  end

  def table_columns
    params[:page] = 1 if params[:page].blank?

    result_hash = @source.table_columns(current_user, params[:table], params[:page].to_i, 20, params[:filter_unmapped] == '1')
    @columns = result_hash[:result]
    @max_pages = result_hash[:max_pages]
    @error = result_hash[:error]
    params[:page] = result_hash[:page] unless result_hash[:page].blank?
  end

  # GET /sources
  # GET /sources.json
  def index
    @order = scrub_order(Source, params[:order], 'sources.name')

    if [params[:autocomplete], params[:popup]].include?('true')
      source_scope = Source.available
    else
      source_scope = Source.available_or_creator_id(current_user.id)
    end

    @search_terms = (params[:search] || params[:term] || params[:sources_search]).to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| source_scope = source_scope.search(search_term) }

    source_scope = source_scope.order(@order)

    @sources = source_scope.page(params[:page]).per( 20 )
    @query = current_user.queries.find_by_id(params[:query_id])
    render json: @sources.collect{|s| { id: s.id.to_s, text: s.name }} if params[:autocomplete] == 'true'
    render 'popup' if params[:popup] == 'true'
  end

  # GET /sources/1
  # GET /sources/1.json
  def show
    if params[:popup] == 'true'
      @source = Source.available.find_by_id(params[:id])
      @query = current_user.queries.find_by_id(params[:query_id])
      if @source and @query
        render 'info'
      else
        render nothing: true
      end
      return
    else
      @source = current_user.all_sources.find_by_id(params[:id])
      source = Source.find_by_id(params[:id])
      @source = source if (not @source) and source and (source.user_has_action_group?(current_user, "All Read") or source.user_has_action_group?(current_user, "All Write"))
      @query = current_user.queries.find_by_id(params[:query_id])
    end
    redirect_to root_path unless @source
  end

  # GET /sources/new
  def new
    @source = current_user.sources.new
  end

  # GET /sources/1/edit
  def edit
  end

  # POST /sources
  # POST /sources.json
  def create
    @source = current_user.sources.new(source_params)

    if @source.save
      redirect_to @source, notice: 'Database was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /sources/1
  # PUT /sources/1.json
  def update
    if @source.update(source_params)
      flash[:notice] = 'Source was successfully updated.'
      redirect_to(@source)
    else
      render action: 'edit'
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.json
  def destroy
    @source.destroy
    redirect_to sources_path
  end

  private

    def set_source
      set_source_with_actions
    end

    def set_source_with_edit_data_source_connection_information
      set_source_with_actions(["edit data source connection information"])
    end

    def set_source_with_edit_data_source_mappings
      set_source_with_actions(["edit data source mappings"])
    end

    def set_source_with_view_or_edit_data_source_mappings
      set_source_with_actions(["edit data source mappings"])
      unless @source
        render 'mapping_privilege'
        return
      end
    end

    def set_source_with_actions(actions = [])
      @source = current_user.all_sources.find_by_id(params[:id])
      source = Source.find_by_id(params[:id])
      @source = source if (not @source) and source and source.user_has_one_or_more_actions?(current_user, actions)
    end

    def redirect_without_source
      empty_response_or_root_path(sources_path) unless @source
    end

    def source_params
      params.require(:source).permit(
        :name, :description, :host, :port, :wrapper, :database, :username, :password, :visible, :repository, :file_server_host, :file_server_login, :file_server_password, :file_server_path
      )
    end

end
