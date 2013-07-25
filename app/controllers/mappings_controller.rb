class MappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source_with_edit_data_source_mappings, only: [ :info, :automap_popup, :show, :create, :destroy ]
  before_action :redirect_without_source,                   only: [ :info, :automap_popup, :show, :create, :destroy ]
  before_action :set_mapping,                               only: [ :info, :show, :destroy ]
  before_action :redirect_without_mapping,                  only: [ :info, :show, :destroy ]

  def automap_popup
  end

  def info
    @defaults = { title: @mapping.variable.display_name, width: '320px', height: '240px', units: '', legend: 'right' }
    case @mapping.variable.variable_type when 'numeric', 'integer', 'date'
      @defaults[:width] = '680px'
      @defaults[:height] = '300px'
      @defaults[:units] = @mapping.variable.units
      @defaults[:legend] = 'none'
    when 'choices'
      @defaults[:width] = '450px'
      @defaults[:height] = '250px'
    end

    @chart_element_id = "variable_chart_#{@mapping.variable.id}"
    result_hash = @mapping.graph_values(current_user)
    @values = result_hash[:values]
    @categories = result_hash[:categories]
  end

  # GET /mappings/1
  def show
  end

  # POST /mappings
  def create
    @mapping = @source.mappings.create(mapping_params)
    render 'show'
  end

  # DELETE /mappings/1.js
  def destroy
    @column = @mapping.column
    params[:table] = @mapping.table
    @source.mappings.where( table: @mapping.table, column: @mapping.column ).destroy_all
    render 'new'
  end

  private

    def set_mapping
      @mapping = Mapping.find_by_id(params[:id])
      @mapping = nil if @mapping and not @mapping.source.user_has_action?(current_user, "edit data source mappings")
    end

    def redirect_without_mapping
      empty_response_or_root_path unless @mapping
    end

    def mapping_params
      params.require(:mapping).permit(
        :table, :column, :variable_id
      )
    end
end
