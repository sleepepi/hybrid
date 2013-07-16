class QueryConceptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_query,               only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]
  before_action :redirect_without_query,  only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]

  def select_all
    @query.query_concepts.update_all(selected: (params[:selected] == 'true'))
    @query.reload
    render 'query_concepts/query_concepts'
  end

  def mark_selected
    @query_concept = @query.query_concepts.find_by_id(params[:query_concept_id])
    @query_concept.update_column :selected, (params[:selected] == 'true') if @query_concept
    render nothing: true
  end

  def copy_selected
    if @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).each do |query_concept|
        qc_attributes = query_concept.copyable_attributes
        qc_attributes[:position] = @query.query_concepts.size
        qc_attributes[:selected] = false
        @query.query_concepts.create(qc_attributes)
      end

      @query.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def trash_selected
    if @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).destroy_all
      @query.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def indent
    params[:indent] = 0 unless (-2..2).to_a.include?(params[:indent].to_i)
    if @query.query_concepts.where(selected: true).size > 0
      @query.query_concepts.where(selected: true).each do |query_concept|
        query_concept.update_attributes level: [query_concept.level + params[:indent].to_i, 0].max
      end

      @query.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def right_operator
    @query_concept = @query.query_concepts.find_by_id(params[:query_concept_id])
    if @query_concept
      @query_concept.update_attributes right_operator: params[:right_operator] if QueryConcept::OPERATOR.include?(params[:right_operator])
      @query.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def edit
    @query_concept = @query.query_concepts.find_by_id(params[:id])

    chart_params = { title: @query_concept.variable.display_name, width: '100%', make_selection: true }
    case @query_concept.variable.variable_type when 'numeric', 'integer', 'date'
      chart_params[:height] = '300px'
      chart_params[:units] = @query_concept.variable.units
      chart_params[:legend] = 'none'
    when 'choices'
      chart_params[:height] = '250px'
    end

    result_hash = @query_concept.variable.graph_values(current_user, chart_params)
    @values = result_hash[:values]
    @categories = result_hash[:categories]
    @chart_type = result_hash[:chart_type]
    @chart_element_id = result_hash[:chart_element_id]
    @defaults = result_hash[:defaults]

    render nothing: true unless @query_concept
  end

  def create
    variable = Variable.current.find_by_id(params[:variable_id])
    @query.query_concepts << @query.query_concepts.create(variable_id: variable.id, position: @query.query_concepts.size) if variable
    @query.reload
    render 'query_concepts/query_concepts'
  end

  def update
    @query_concept = @query.query_concepts.find_by_id(params[:id])
    if @query_concept
      params[:query_concept] = {} if params[:query_concept].blank?
      params[:query_concept][:right_operator] = 'and' unless QueryConcept::OPERATOR.include?(params[:query_concept][:right_operator])
      if @query_concept.variable.variable_type == 'date'
        params[:start_date] = Date.strptime(params[:start_date], "%m/%d/%Y") unless params[:start_date].blank?
        params[:end_date] = Date.strptime(params[:end_date], "%m/%d/%Y") unless params[:end_date].blank?
        params[:query_concept][:value] = "#{params[:start_date]}:#{params[:end_date]}"
      elsif params[:values].blank? and @query_concept.variable.variable_type == 'choices'
        params[:query_concept][:value] = ''
      elsif not params[:values].blank?
        params[:query_concept][:value] = params[:values].join(',')
      end
      @query_concept.update(query_concept_params)
      @query.reload
    end
    render 'query_concepts/query_concepts'
  end

  def destroy
    @query_concept = @query.query_concepts.find_by_id(params[:id])
    if @query_concept
      @query_concept.destroy
      @query.update_brackets!
      @query.reload
    end
    render 'query_concepts/query_concepts'
  end

  private

    def query_concept_params
      params.require(:query_concept).permit(
        :value, :right_operator, :negated, :source_id
      )
    end
end
