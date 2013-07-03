class QuerySourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_query,               only: [ :show, :create, :destroy ]
  before_action :redirect_without_query,  only: [ :show, :create, :destroy ]

  def show
    @query_source = @query.query_sources.find_by_id(params[:id])
    @source = @query_source.source if @query_source
    if @source and @query and current_user.all_queries.include?(@query)
      @order = 'sources.name'
      source_scope = Source.available
      source_scope = source_scope.order(@order)
      @sources = source_scope.page(params[:page]).per(20)
      render 'sources/popup'
    else
      render nothing: true
    end
  end

  def create
    @source = Source.available.find_by_id(query_source_params[:source_id])
    @query.sources << @source if @source and not @query.sources.include?(@source)
    render 'query_sources/query_sources'
  end

  def destroy
    @query_source = @query.query_sources.find_by_id(params[:id])
    if @query_source
      @query_source.destroy
      @query.reload
    end
    render 'query_sources/query_sources'
  end

  private

    def query_source_params
      params.require(:query_source).permit(
        :source_id
      )
    end

end
