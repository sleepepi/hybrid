class QuerySourcesController < ApplicationController
  before_action :authenticate_user!

  def show
    @query_source = QuerySource.find_by_id(params[:id])
    @source = @query_source.source if @query_source
    @query = @query_source.query if @query_source
    if @source and @query and current_user.all_queries.include?(@query)
      @order = 'sources.name'
      source_scope = Source.available
      source_scope = source_scope.order(@order)
      @sources = source_scope.page(params[:page]).per(20) #params[:page]).per(current_user.sources_per_page)
      render 'sources/popup'
    else
      render nothing: true
    end
  end

  def create
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @source = Source.available.find_by_id(params[:selected_source_id])
    if @query
      @query.sources << @source if @source and not @query.sources.include?(@source)
      render 'query_sources/query_sources'
    else
      render nothing: true
    end
  end

  def destroy
    @query_source = QuerySource.find_by_id(params[:id])
    @query = @query_source.query if @query_source and current_user.all_queries.include?(@query_source.query)
    @source = @query_source.source if @query_source
    if @query and @query_source
      @query_source.destroy
      @query.reload
      render 'query_sources/query_sources'
    else
      render nothing: true
    end
  end
end
