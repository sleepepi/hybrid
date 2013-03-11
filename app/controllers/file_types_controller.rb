class FileTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin

  def index
    @file_types = current_user.file_types.all
    file_type_scope = FileType.current

    @order = scrub_order(FileType, params[:order], 'file_types.name')
    file_type_scope = file_type_scope.order(@order)

    @file_types = file_type_scope.page(params[:page]).per( 20 )

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.json { render json: @file_types }
    end
  end

  def show
    @file_type = current_user.file_types.find_by_id(params[:id])
    redirect_to root_path unless @file_type
  end

  def new
    @file_type = current_user.file_types.new
  end

  def edit
    @file_type = current_user.file_types.find_by_id(params[:id])
    redirect_to root_path unless @file_type
  end

  def create
    @file_type = current_user.file_types.new(params[:file_type])

    if @file_type.save
      redirect_to @file_type, notice: 'File type was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    @file_type = current_user.file_types.find_by_id(params[:id])

    unless @file_type
      redirect_to root_path
      return
    end

    if @file_type.update_attributes(params[:file_type])
      redirect_to @file_type, notice: 'File type was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @file_type = current_user.file_types.find_by_id(params[:id])

    if @file_type
      @file_type.destroy
      redirect_to file_types_path
    else
      redirect_to root_path
    end
  end
end
