class SourceFileTypesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    if @source
      @source_file_types = @source.source_file_types
    else
      redirect_to root_path
    end
  end

  def show
    source_file_type = SourceFileType.find_by_id(params[:id])
    @source = current_user.all_sources.find_by_id(source_file_type.source_id)
    source = Source.find_by_id(source_file_type.source_id)
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    redirect_to root_path, alert: "Source File Type not found." unless @source and @source_file_type = @source.source_file_types.find(params[:id])
  end

  def new
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    redirect_to root_path, alert: "You do not have access to this source." unless @source and @source_file_type = @source.source_file_types.new()
  end

  def edit
    source_file_type = SourceFileType.find_by_id(params[:id])
    @source = current_user.all_sources.find_by_id(source_file_type.source_id)
    source = Source.find_by_id(source_file_type.source_id)
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    redirect_to root_path, alert: "Source File Type not found." unless @source and @source_file_type = @source.source_file_types.find(params[:id])
  end

  def create
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    if @source
      @source_file_type = @source.source_file_types.new(params[:source_file_type])
      if @source_file_type.save
        redirect_to @source_file_type, notice: 'Source File Type was successfully created.'
      else
        render action: "new"
      end
    else
      redirect_to root_path, alert: "You do not have access to this source."
    end
  end

  def update
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    if @source and @source_file_type = @source.source_file_types.find(params[:id])
      if @source_file_type.update_attributes(params[:source_file_type])
        redirect_to @source_file_type, notice: 'Source File Type was successfully updated.'
      else
        render action: "edit"
      end
    else
      redirect_to root_path, alert: "Source File Type not found."
    end
  end

  def destroy
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")
    if @source and @source_file_type = @source.source_file_types.find(params[:id])
      @source_file_type.destroy
      redirect_to source_file_types_path(source_id: @source.id), notice: "Source File Type Deleted."
    else
      redirect_to root_path, alert: "Source File Type not found."
    end
  end
end
