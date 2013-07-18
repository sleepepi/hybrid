class MappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source_with_edit_data_source_mappings, only: [ :info, :automap_popup, :show, :edit, :create, :update, :destroy ]
  before_action :redirect_without_source,                   only: [ :info, :automap_popup, :show, :edit, :create, :update, :destroy ]
  before_action :set_mapping,                               only: [ :info, :show, :edit, :update, :destroy ]
  before_action :redirect_without_mapping,                  only: [ :info, :show, :edit, :update, :destroy ]

  def automap_popup
  end

  def info
    chart_params = { title: @mapping.variable.display_name }
    case @mapping.variable.variable_type when 'numeric', 'integer', 'date'
      chart_params[:width] = 680
      chart_params[:height] = 300
      chart_params[:units] = @mapping.variable.units
      chart_params[:legend] = 'none'
    when 'choices'
      chart_params[:width] = 450
      chart_params[:height] = 250
    end

    @chart_element_id = "variable_chart_#{@mapping.variable.id}"
    result_hash = @mapping.graph_values(current_user, chart_params)
    @values = result_hash[:values]
    @categories = result_hash[:categories]
    @chart_type = result_hash[:chart_type]
    @defaults = result_hash[:defaults]
  end

  # GET /mappings/1
  def show
  end

  # GET /mappings/1/edit
  def edit
  end

  # POST /mappings
  def create
    @mapping = @source.mappings.create(mapping_params)
    render 'show'
  end

  # PATCH /mappings/1
  def update
    (mapping_params[:column_values] || []).each do |column_value_hash|
      column_value = column_value_hash[:is_null] == 'true' ? nil : column_value_hash[:column_value]
      value = column_value_hash[:value]
      val_mapping = @source.mappings.where( table: @mapping.table, column: @mapping.column, column_value: (column_value == nil ? 'NULL' : column_value.to_s) ).first_or_create

      value = value.blank? ? nil : value
      if @mapping.concept
        if Concept.find_by_id(value)
          val_mapping.update( concept_id: value, value: nil )
        else
          val_mapping.update( concept_id: @mapping.concept_id, value: value )
        end
      end
    end
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
