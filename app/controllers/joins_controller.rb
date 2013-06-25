class JoinsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source,                only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :redirect_without_source,   only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :set_join,                  only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_join,     only: [ :show, :edit, :update, :destroy ]


  # GET /sources/1/joins
  # GET /sources/1/joins.json
  def index
    @order = scrub_order(Join, params[:order], 'joins.source_id')
    @joins = @source.joins.search(params[:search]).order(@order).page(params[:page]).per( 20 )
  end

  # GET /sources/1/joins/1
  # GET /sources/1/joins/1.json
  def show
  end

  # GET /sources/1/joins/new
  def new
    @join = @source.joins.new
  end

  # GET /sources/1/joins/1/edit
  def edit
  end

  # POST /sources/1/joins
  # POST /sources/1/joins.json
  def create
    @join = @source.joins.new(join_params)

    if @join.save
      redirect_to [@join.source, @join], notice: 'Join was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /sources/1/joins/1
  # PUT /sources/1/joins/1.json
  def update
    if @join.update(join_params)
      redirect_to [@join.source, @join], notice: 'Join was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /sources/1/joins/1
  # DELETE /sources/1/joins/1.json
  def destroy
    @join.destroy

    redirect_to source_joins_path(@source)
  end

  private

    def set_source
      @source = current_user.all_sources.find_by_id(params[:source_id])
      source = Source.find_by_id(params[:source_id])
      @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    end

    def set_join
      @join = @source.joins.find_by_id(params[:id])
    end

    def redirect_without_join
      empty_response_or_root_path(source_joins_path(@source)) unless @join
    end

    def join_params
      params.require(:join).permit(
        :from_table, :from_column, :to_table, :to_column
      )
    end

end
