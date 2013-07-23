class SourcesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_source, only: [ :destroy ]
  before_action :set_source_with_edit_data_source_connection_information, only: [ :edit, :update ]
  before_action :set_source_with_edit_data_source_mappings, only: [ :auto_map, :remove_all_mappings ]
  before_action :set_source_with_view_or_edit_data_source_mappings, only: [ :table_columns ]
  before_action :set_source_with_download_files, only: [ :download_file ]
  before_action :redirect_without_source,     only: [ :destroy, :edit, :update, :auto_map, :remove_all_mappings, :download_file ]
  before_action :set_viewable_dictionary,     only: [ :auto_map ]
  before_action :redirect_without_dictionary, only: [ :auto_map ]

  def download_file
    result_hash = Aqueduct::Builder.repository(@source, current_user).get_file(params[:file_locator], params[:file_type])
    file_path = result_hash[:file_path]
    if result_hash[:error].blank? and File.exists?(file_path.to_s)
      send_file file_path, disposition:'attachment'
    else
      render text: "File not found on server..."
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
        variables = @dictionary.variables.where( 'LOWER(name) = ?', column_hash[:column].to_s.downcase )
        if variables.size == 1 and v = variables.first
          @source.mappings.where( variable_id: v.id, table: table, column: column_hash[:column] ).first_or_create
        end
      end

    end

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

    result_hash = @source.table_columns(current_user, params[:table], params[:page].to_i, 20, params[:filter_unmapped] == '1', params[:search])
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
    @search = current_user.searches.find_by_id(params[:search_id])
    render json: @sources.collect{|s| { id: s.id.to_s, text: s.name }} if params[:autocomplete] == 'true'
    render 'popup' if params[:popup] == 'true'
  end

  # GET /sources/1
  # GET /sources/1.json
  def show
    if params[:popup] == 'true'
      @source = Source.available.find_by_id(params[:id])
      @search = current_user.searches.find_by_id(params[:search_id])
      if @source and @search
        render 'info'
      else
        render nothing: true
      end
      return
    else
      @source = current_user.all_sources.find_by_id(params[:id])
      source = Source.find_by_id(params[:id])
      @source = source if (not @source) and source and (source.user_has_action_group?(current_user, "All Read") or source.user_has_action_group?(current_user, "All Write"))
      @search = current_user.searches.find_by_id(params[:search_id])
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
      redirect_to @source, notice: 'Source was successfully created.'
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
      set_source_with_actions(:id)
    end

    def set_source_with_edit_data_source_connection_information
      set_source_with_actions(:id, ["edit data source connection information"])
    end

    def set_source_with_edit_data_source_mappings
      super(:id)
    end

    def set_source_with_download_files
      set_source_with_actions(:id, ["download files"])
    end

    def set_source_with_view_or_edit_data_source_mappings
      set_source_with_actions(:id, ["edit data source mappings"])
      unless @source
        render 'mapping_privilege'
        return
      end
    end

    def source_params
      params.require(:source).permit(
        :name, :description, :host, :port, :wrapper, :database, :username, :password, :visible, :repository, :file_server_host, :file_server_login, :file_server_password, :file_server_path
      )
    end

end
