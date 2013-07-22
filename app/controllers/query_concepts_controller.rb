class QueryConceptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search,              only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]
  before_action :redirect_without_search, only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]

  def select_all
    @search.query_concepts.update_all(selected: (params[:selected] == 'true'))
    @search.reload
    render 'query_concepts/query_concepts'
  end

  def mark_selected
    @query_concept = @search.query_concepts.find_by_id(params[:query_concept_id])
    @query_concept.update_column :selected, (params[:selected] == 'true') if @query_concept
    render nothing: true
  end

  def copy_selected
    if @search.query_concepts.where(selected: true).size > 0
      @search.query_concepts.where(selected: true).each do |query_concept|
        qc_attributes = query_concept.copyable_attributes
        qc_attributes[:position] = @search.query_concepts.size
        qc_attributes[:selected] = false
        @search.query_concepts.create(qc_attributes)
      end

      @search.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def trash_selected
    if @search.query_concepts.where(selected: true).size > 0
      @search.query_concepts.where(selected: true).destroy_all
      @search.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def indent
    params[:indent] = 0 unless (-2..2).to_a.include?(params[:indent].to_i)
    if @search.query_concepts.where(selected: true).size > 0
      @search.query_concepts.where(selected: true).each do |query_concept|
        query_concept.update_attributes level: [query_concept.level + params[:indent].to_i, 0].max
      end

      @search.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def right_operator
    @query_concept = @search.query_concepts.find_by_id(params[:query_concept_id])
    if @query_concept
      @query_concept.update_attributes right_operator: params[:right_operator] if QueryConcept::OPERATOR.include?(params[:right_operator])
      @search.update_brackets!
    end
    render 'query_concepts/query_concepts'
  end

  def edit
    @query_concept = @search.query_concepts.find_by_id(params[:id])

    @defaults = { title: @query_concept.variable.display_name, width: '100%', make_selection: true, height: '240px', units: '', title: '', legend: 'right' }
    case @query_concept.variable.variable_type when 'numeric', 'integer', 'date'
      @defaults[:height] = '300px'
      @defaults[:units] = @query_concept.variable.units
      @defaults[:legend] = 'none'
    when 'choices'
      @defaults[:height] = '250px'
    end

    @chart_element_id = "variable_chart_#{@query_concept.variable.id}"
    result_hash = @query_concept.variable.graph_values(current_user)
    @values = result_hash[:values]
    @categories = result_hash[:categories]

    render nothing: true unless @query_concept
  end

  def create
    variable = Variable.current.find_by_id(params[:variable_id])
    @search.query_concepts << @search.query_concepts.create(variable_id: variable.id, position: @search.query_concepts.size) if variable
    @search.reload
    render 'query_concepts/query_concepts'
  end

  def update
    @query_concept = @search.query_concepts.find_by_id(params[:id])
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
      @search.reload
    end
    render 'query_concepts/query_concepts'
  end

  def destroy
    @query_concept = @search.query_concepts.find_by_id(params[:id])
    if @query_concept
      @query_concept.destroy
      @search.update_brackets!
      @search.reload
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
