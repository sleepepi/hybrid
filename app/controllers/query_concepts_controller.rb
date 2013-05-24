class QueryConceptsController < ApplicationController
  before_action :authenticate_user!

  def select_all
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @query
      @query.query_concepts.update_all(selected: (params[:selected] == 'true'))
      @query.reload
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def mark_selected
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @query_concept = @query.query_concepts.find_by_id(params[:query_concept_id]) if @query
    @query_concept.update_column :selected, (params[:selected] == 'true') if @query and @query_concept
    render nothing: true
  end

  def copy_selected
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @query and @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).each do |query_concept|

        qc_attributes = query_concept.copyable_attributes
        qc_attributes[:position] = @query.query_concepts.size
        qc_attributes[:selected] = false
        @query.query_concepts.create(qc_attributes)
      end

      @query.update_brackets!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def trash_selected
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @query and @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).destroy_all
      @query.update_brackets!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def indent
    params[:indent] = 0 unless (-2..2).to_a.include?(params[:indent].to_i)
    @query = current_user.all_queries.find_by_id(params[:query_id])
    if @query and @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).each do |query_concept|
        query_concept.update_attributes level: [query_concept.level + params[:indent].to_i, 0].max
      end

      @query.update_brackets!

      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def right_operator
    @query = current_user.all_queries.find_by_id(params[:query_id])
    @query_concept = @query.query_concepts.find_by_id(params[:query_concept_id]) if @query
    if @query and @query_concept
      @query_concept.update_attributes right_operator: params[:right_operator] if QueryConcept::OPERATOR.include?([params[:right_operator], params[:right_operator]])
      @query.update_brackets!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def edit
    @query_concept = QueryConcept.find(params[:id])
    @query = @query_concept.query if @query_concept and current_user.all_queries.include?(@query_concept.query)
    @concept = @query_concept.concept if @query_concept

    if @concept and @concept.mappings.size > 0
      chart_params = {}
      width = "100%"
      if @concept.continuous? or @concept.date?
        chart_params = { title: @concept.human_name, width: width, height: "300px", units: @concept.human_units, legend: 'none', make_selection: true }
      elsif @concept.categorical? or @concept.boolean?
        chart_params = { title: @concept.human_name, width: width, height: "250px", make_selection: true }
      end

      result_hash = @concept.graph_values(current_user, chart_params)
      @values = result_hash[:values]
      @categories = result_hash[:categories]
      @chart_type = result_hash[:chart_type]
      @chart_element_id = result_hash[:chart_element_id]
      @stats = result_hash[:stats]
      @defaults = result_hash[:defaults]

      @mapping = 1
    end

    render nothing: true unless @query and @query_concept
  end

  def create
    @query = current_user.all_queries.find_by_id(params[:query_id])
    concept = Concept.current.find_by_id(params[:selected_concept_id])

    unless concept or params[:selected_concept_id] =~ /^[0-9]+$/ or params[:selected_concept_id].blank? or not params[:external_key].blank?
      params[:source_id] = params[:selected_concept_id].split(',').first
      params[:external_key] = params[:selected_concept_id].split(',')[1..-1].join(',')
    end

    # external_concept = Concept.new(name: params[:name], totalnum: params[:totalnum], key: params[:key])
    if @query and concept
      @query.query_concepts << @query.query_concepts.create(concept_id: concept.id, position: @query.query_concepts.size)
      @query.reload
      render 'query_concepts/query_concepts'
    elsif @query and not params[:source_id].blank? and not params[:external_key].blank?
      @query.query_concepts << @query.query_concepts.create(external_key: params[:external_key], source_id: params[:source_id], position: @query.query_concepts.size)
      @query.reload
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  def update
    @query_concept = QueryConcept.find_by_id(params[:id])
    @query = @query_concept.query if @query_concept and current_user.all_queries.include?(@query_concept.query)
    if @query and @query_concept
      params[:query_concept] = {} if params[:query_concept].blank?
      params[:query_concept][:right_operator] = 'and' unless QueryConcept::OPERATOR.include?([params[:query_concept][:right_operator], params[:query_concept][:right_operator]])
      if @query_concept.concept and @query_concept.concept.date?
        params[:start_date] = Date.strptime(params[:start_date], "%m/%d/%Y") unless params[:start_date].blank?
        params[:end_date] = Date.strptime(params[:end_date], "%m/%d/%Y") unless params[:end_date].blank?
        params[:query_concept][:value] = "#{params[:start_date]}:#{params[:end_date]}"
      elsif params[:value_ids].blank? and @query_concept.concept and (@query_concept.concept.categorical? or @query_concept.concept.boolean?)
        params[:query_concept][:value] = ''
      elsif not params[:value_ids].blank?
        params[:query_concept][:value] = params[:value_ids].keys.join(',')
      end
      @query_concept.update_attributes(query_concept_params)
      render 'query_concepts/query_concepts'
      # render "show"
    else
      render nothing: true
    end
  end

  def destroy
    @query_concept = QueryConcept.find_by_id(params[:id])
    @query = @query_concept.query if @query_concept and current_user.all_queries.include?(@query_concept.query)
    if @query and @query_concept
      @query_concept.destroy
      @query.update_brackets!
      render 'query_concepts/query_concepts'
    else
      render nothing: true
    end
  end

  private

    def query_concept_params
      params.require(:query_concept).permit(
        :value, :right_operator, :negated, :source_id
      )
    end
end
