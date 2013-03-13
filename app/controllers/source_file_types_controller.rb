class SourceFileTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source, only: [ :index, :show, :new, :edit, :create, :update, :destroy ] # [ :index, :show, :new, :edit, :create, :update, :destroy, :copy, :add_grid_variable ]
  before_action :redirect_without_source, only: [ :index, :show, :new, :edit, :create, :update, :destroy ] # [ :index, :show, :new, :edit, :create, :update, :destroy, :copy, :add_grid_variable ]
  before_action :set_source_file_type, only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_source_file_type, only: [ :show, :edit, :update, :destroy ]

  # GET /source_file_types
  # GET /source_file_types.json
  def index
    @order = scrub_order(SourceFileType, params[:order], 'source_file_types.file_type_id')
    @source_file_types = @source.source_file_types.order(@order).page(params[:page]).per( 20 )
  end

  # GET /source_file_types/1?source_id=1
  # GET /source_file_types/1.json?source_id=1
  def show
  end

  # GET /source_file_types/new
  def new
    @source_file_type = @source.source_file_types.new
  end

  # GET /source_file_types/1/edit?source_id=1
  def edit
  end

  # POST /source_file_types
  # POST /source_file_types.json
  def create
    @source_file_type = @source.source_file_types.new(source_file_type_params)
    if @source_file_type.save
      redirect_to source_file_type_path(@source_file_type, source_id: @source.id), notice: 'Source File Type was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /source_file_types/1
  # PUT /source_file_types/1.json
  def update
    if @source_file_type.update(source_file_type_params)
      redirect_to source_file_type_path(@source_file_type, source_id: @source.id), notice: 'Source File Type was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /source_file_types/1
  # DELETE /source_file_types/1.json
  def destroy
    @source_file_type.destroy
    redirect_to source_file_types_path(source_id: @source.id), notice: 'Source File Type was successfully deleted.'
  end

  private

    def set_source
      @source = current_user.all_sources.find_by_id(params[:source_id])
      source = Source.find_by_id(params[:source_id])
      @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    end

    def redirect_without_source
      empty_response_or_root_path unless @source
    end

    def set_source_file_type
      @source_file_type = @source.source_file_types.find(params[:id])
    end

    def redirect_without_source_file_type
      empty_response_or_root_path(source_path(@source)) unless @source_file_type
    end

    def source_file_type_params
      params.require(:source_file_type).permit(
        :file_type_id
      )
    end
end
