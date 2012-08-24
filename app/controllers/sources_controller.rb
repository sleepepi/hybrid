class SourcesController < ApplicationController
  before_filter :authenticate_user!

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
    @source = current_user.all_sources.find_by_id(params[:id])

    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    unless @source
      render nothing: true
      return
    end

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
        concepts = Concept.with_dictionary(params[:dictionary_id]).with_namespace(params[:namespace] || '').searchable.exactly(column_hash[:column].to_s.gsub(/[^\w]/, ' ').titleize.downcase, column_hash[:column].to_s.gsub(/[^\w]/, ' ').downcase)
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
    @source = current_user.all_sources.find_by_id(params[:id])
    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    if @source
      @source.mappings.destroy_all
      redirect_to @source
    else
      if source
        redirect_to source
      else
        redirect_to root_path
      end
    end
  end

  def table_columns
    @source = current_user.all_sources.find_by_id(params[:id])
    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and (source.user_has_action?(current_user, "edit data source mappings") or source.user_has_action?(current_user, "view data source mappings"))

    unless @source
      render 'mapping_privilege'
      return
    end

    params[:page] = 1 if params[:page].blank?

    result_hash = @source.table_columns(current_user, params[:table], params[:page].to_i, 20, params[:filter_unmapped] == '1')
    @columns = result_hash[:result]
    @max_pages = result_hash[:max_pages]
    @error = result_hash[:error]
    params[:page] = result_hash[:page] unless result_hash[:page].blank?
  end

  def index
    # current_user.update_column :users_per_page, params[:users_per_page].to_i if params[:users_per_page].to_i >= 10 and params[:users_per_page].to_i <= 200
    @order = params[:order].blank? ? 'sources.name' : params[:order]
    if [params[:autocomplete], params[:popup]].include?('true')
      source_scope = Source.available
    else
      # source_scope = current_user.all_sources
      # sources that are available or sources that are part of the user.
      source_scope = Source.available_or_creator_id(current_user.id)
    end
    @search_terms = (params[:search] || params[:term] || params[:sources_search]).to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| source_scope = source_scope.search(search_term) }
    source_scope = source_scope.order(@order)
    @sources = source_scope.page(params[:page]).per(20) #params[:page]).per(current_user.sources_per_page)
    @query = current_user.queries.find_by_id(params[:query_id])
    render 'autocomplete' if params[:autocomplete] == 'true'
    render 'popup' if params[:popup] == 'true'
  end

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

  def new
    @source = current_user.sources.new
  end

  def edit
    @source = current_user.all_sources.find_by_id(params[:id])
    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source connection information")
    redirect_to root_path unless @source
  end

  def create
    @source = current_user.sources.new(params[:source])

    if @source.save
      flash[:notice] = 'Database was successfully created.'
      redirect_to(@source)
    else
      render action: "new"
    end
  end

  def update
    @source = current_user.all_sources.find_by_id(params[:id])
    source = Source.find_by_id(params[:id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source connection information")

    unless @source
      redirect_to root_path
      return
    end

    if @source.update_attributes(params[:source])
      flash[:notice] = 'Source was successfully updated.'
      redirect_to(@source)
    else
      render action: "edit"
    end
  end

  def destroy
    @source = current_user.all_sources.find_by_id(params[:id])
    if @source
      @source.destroy
      redirect_to sources_path
    else
      redirect_to root_path
    end
  end
end
