class FileTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin
  before_action :set_file_type, only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_file_type, only: [ :show, :edit, :update, :destroy ]

  # GET /file_types
  # GET /file_types.json
  def index
    @order = scrub_order(FileType, params[:order], 'file_types.name')
    @file_types = FileType.current.order(@order).page(params[:page]).per( 20 )
  end

  # GET /file_types/1
  # GET /file_types/1.json
  def show
  end

  # GET /file_types/new
  def new
    @file_type = current_user.file_types.new
  end

  # GET /file_types/1/edit
  def edit
  end

  # POST /file_types
  # POST /file_types.json
  def create
    @file_type = current_user.file_types.new(file_type_params)

    if @file_type.save
      redirect_to @file_type, notice: 'File type was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /file_types/1
  # PUT /file_types/1.json
  def update
    if @file_type.update(file_type_params)
      redirect_to @file_type, notice: 'File type was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /file_types/1
  # DELETE /file_types/1.json
  def destroy
    @file_type.destroy
    redirect_to file_types_path
  end

  private

    def set_file_type
      @file_type = current_user.file_types.find_by_id(params[:id])
    end

    def redirect_without_file_type
      empty_response_or_root_path(file_types_path) unless @file_type
    end

    def file_type_params
      params.require(:file_type).permit(
        :name, :extension, :description, :visible, :dictionary_id
      )
    end

end
