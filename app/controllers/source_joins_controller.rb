class SourceJoinsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin
  before_action :set_source,                    only: [ :index ]
  before_action :set_source_join,               only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_source_join,  only: [ :show, :edit, :update, :destroy ]


  # TODO Make SourceJoins available to user with appropriate source_rules.

  # GET /source_joins
  # GET /source_joins.json
  def index
    @order = scrub_order(SourceJoin, params[:order], 'source_joins.source_id')
    source_join_scope = SourceJoin.current.search(params[:search])
    source_join_scope = source_join_scope.with_source(@source.id) if @source
    @source_joins = source_join_scope.order(@order).page(params[:page]).per( 20 )
  end

  # GET /source_joins/1
  # GET /source_joins/1.json
  def show
  end

  # GET /source_joins/new
  def new
    @source_join = SourceJoin.new({ source_id: params[:source_id] })
  end

  # GET /source_joins/1/edit
  def edit
  end

  # POST /source_joins
  # POST /source_joins.json
  def create
    @source_join = SourceJoin.new(source_join_params)

    if @source_join.save
      redirect_to @source_join, notice: 'Join was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /source_joins/1
  # PUT /source_joins/1.json
  def update
    if @source_join.update(source_join_params)
      redirect_to @source_join, notice: 'Join was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /source_joins/1
  # DELETE /source_joins/1.json
  def destroy
    @source_join.destroy
    redirect_to source_joins_path
  end

  private

    def set_source
      @source = current_user.all_sources.find_by_id(params[:source_id])
      source = Source.find_by_id(params[:source_id])
      @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    end

    def set_source_join
      @source_join = SourceJoin.find_by_id(params[:id])
    end

    def redirect_without_source_join
      empty_response_or_root_path(source_joins_path) unless @source_join
    end

    def source_join_params
      params.require(:source_join).permit(
        :source_id,    :from_table, :from_column,
        :source_to_id, :to_table,   :to_column
      )
    end

end
