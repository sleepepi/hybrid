class MappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source_with_edit_data_source_mappings, only: [ :automap_popup, :show, :edit, :create, :update, :destroy ]
  before_action :redirect_without_source, only: [ :automap_popup, :show, :edit, :create, :update, :destroy ]
  before_action :set_mapping, only: [ :expanded, :show, :edit, :update, :destroy ]
  before_action :redirect_without_mapping, only: [ :expanded, :show, :edit, :update, :destroy ]

  def automap_popup
  end

  def info
    @mapping = Mapping.find_by_id(params[:id])
    @concept = @mapping.concept if @mapping

    @query = current_user.queries.new()

    params['concept_search'] = @concept.search_name if @concept

    if @mapping
      chart_params = {}
      if @mapping.concept.continuous? or @mapping.concept.date?
        chart_params = { title: @mapping.concept.human_name, width: 381, height: 300, units: @mapping.concept.human_units, legend: 'none' }
      elsif @mapping.concept.categorical? or @mapping.concept.boolean?
        chart_params = { title: @mapping.concept.human_name, width: 381, height: 250 }
      end

      result_hash = @mapping.graph_values(current_user, chart_params)
      @values = result_hash[:values]
      @categories = result_hash[:categories]
      @chart_type = result_hash[:chart_type]
      @chart_element_id = result_hash[:chart_element_id]
      @stats = result_hash[:stats]
      @defaults = result_hash[:defaults]
    end

    render nothing: true unless @concept
  end

  def expanded
    chart_params = {}
    if @mapping.concept.continuous? or @mapping.concept.date?
      chart_params = { title: @mapping.concept.human_name, width: 680, height: 300, units: @mapping.concept.human_units, legend: 'none' }
    elsif @mapping.concept.categorical? or @mapping.concept.boolean?
      chart_params = { title: @mapping.concept.human_name, width: 450, height: 250 }
    end

    result_hash = @mapping.graph_values(current_user, chart_params)
    @values = result_hash[:values]
    @categories = result_hash[:categories]
    @chart_type = result_hash[:chart_type]
    @chart_element_id = result_hash[:chart_element_id]
    @stats = result_hash[:stats]
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
    @concept = Concept.find_by_id(params[:concept_id])
    if @concept
      @mapping = @source.mappings.create( table: params[:table], column: params[:column], concept_id: @concept.id )
      @mapping.automap(current_user)
    end
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
      params[:mapping] ||= { blank: true }
      params.require(:mapping).permit(
        { :column_values => [ :value, :column_value, :is_null ] }
      )
    end
end
