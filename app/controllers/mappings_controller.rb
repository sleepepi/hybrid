class MappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mapping, only: [ :expanded, :show, :edit, :destroy ]
  before_action :redirect_without_mapping, only: [ :expanded, :show, :edit, :destroy ]

  def info
    @mapping = Mapping.find_by_id(params[:id])
    @concept = @mapping.concept if @mapping

    @query = current_user.queries.new()

    params['concept_search'] = @concept.search_name if @concept

    if @mapping
      chart_params = {}
      if @mapping.concept.continuous? or @mapping.concept.date?
        chart_params = {title: @mapping.concept.human_name, width: 381, height: 300, units: @mapping.human_units, legend: 'none'}
      elsif @mapping.concept.categorical? or @mapping.concept.boolean?
        chart_params = {title: @mapping.concept.human_name, width: 381, height: 250}
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

  def typeahead
    @source = Source.find_by_id(params[:source_id])
    @search_terms = (params[:search] || params[:term]).to_s.strip.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')

    if @search_terms.blank?
      @concepts = []
    else
      concept_scope = Concept.searchable.order('search_name')
      @search_terms.each{|search_term| concept_scope = concept_scope.search(search_term) }
      @concepts = concept_scope.order('dictionary_id')
    end

    # render json: [{ id: '1', value: 'aaa'}, {id: '2', value: 'cat'}]
    render json: @concepts.collect{|c| { id: c.id.to_s, value: c.human_name }}
  end

  def expanded
    chart_params = {}
    if @mapping.concept.continuous? or @mapping.concept.date?
      chart_params = { title: @mapping.concept.human_name, width: 680, height: 300, units: @mapping.human_units, legend: 'none' }
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
    @mapping.set_status!(current_user)
  end

  # GET /mappings/1/edit
  def edit
  end

  # POST /mappings
  def create
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    @concept = Concept.find_by_id(params[:new_concept_id])
    if @source and @concept
      @mapping = @source.mappings.where( table: params[:table], column: params[:new_column] ).first_or_create
      flash[:notice] = 'Mapping Created'

      @mapping.update_attributes(units: @concept.units, concept_id: @concept.id, deleted: false)
      @mapping.reload
      @mapping.set_status!(current_user)

      if @mapping.mapped?
        render 'show'
      else
        render 'edit'
      end
    else
      render nothing: true
    end
  end

  # TODO: Rewrite to use just def update (refactor)
  def update_multiple
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    params[:mapping_ids] = [params[:selected_mapping_id].to_i] unless params[:selected_mapping_id].blank?

    if not @source or params[:mapping_ids].blank?
      render nothing: true
    else
      @mappings = @source.mappings.find(params[:mapping_ids])
      @mappings.each do |mapping|
        @mapping = mapping
        current_time = Time.now

        if params[:mappings][@mapping.id.to_s]

          if params[:mappings][@mapping.id.to_s][:mapping_column_values]
            params[:mappings][@mapping.id.to_s][:mapping_column_values].each do |column_value, value_hash|
              value = value_hash[:value]
              if value_hash[:is_null] == 'true'
                column_value = nil
              elsif column_value == "value_&lt;&#33;&#91;CDATA&#91;&#93;&#93;&gt;"
                column_value = ''
              else
                column_value = column_value[6..-1]  # Strip off "value_" from front of values
              end
              # .gsub('&lt;', '<').gsub('&gt;', '>')
              column_value = column_value.gsub('&#33;', '!').gsub('&#91;', '[').gsub('&#93;', ']').gsub('&#32;', ' ') if column_value
              val_mapping = @source.mappings.where( table: @mapping.table, column: @mapping.column, column_value: (column_value == nil ? 'NULL' : column_value.to_s) ).first_or_create

              value = value.blank? ? nil : value
              if @mapping.concept
                if Concept.find_by_id(value)
                  val_mapping.update_attributes(concept_id: value, value: nil, status: 'mapped', deleted: false)
                else
                  val_mapping.update_attributes(concept_id: @mapping.concept_id, value: value, status: (value == nil) ? 'unmapped' : 'mapped', deleted: false)
                end
              end
            end
          end

          @mapping.reload
          # TODO: Remove Mappings that no longer exist in the underlying data source
          # @mapping.database_concept_column_values.where(["time_stamp != ?", current_time]).each {|dccv| dccv.destroy}

          params[:mappings][@mapping.id.to_s].reject!{|key, value| ['mapping_column_values'].include?(key.to_s)}

          if @mapping.update_attributes(params[:mappings][@mapping.id.to_s])
            @mapping.set_status!(current_user)
            flash[:notice] = 'Mapping was successfully updated.'
          end
        end
      end

      table_div_name = params[:table].gsub(/[^\w\-]/, '_')
      result_hash = @source.table_columns(current_user, params[:table])
      @columns = result_hash[:result]
      all_column_names = @columns.collect{|a| a[:column]}
    end
  end

  # DELETE /mappings/1.js
  def destroy
    flash[:notice] = 'Database Concept was deleted.'

    @column = @mapping.column
    @source = @mapping.source
    @table = @mapping.table
    @mapping_id = @mapping.id

    @mapping.destroy

    # TODO: Update number of mapped concepts
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

end
