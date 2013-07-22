class CriteriaController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search,              only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]
  before_action :redirect_without_search, only: [ :select_all, :mark_selected, :copy_selected, :trash_selected, :indent, :right_operator, :create, :edit, :update, :destroy ]

  def select_all
    @search.criteria.update_all(selected: (params[:selected] == 'true'))
    @search.reload
    render 'criteria/criteria'
  end

  def mark_selected
    @criterium = @search.criteria.find_by_id(params[:criterium_id])
    @criterium.update_column :selected, (params[:selected] == 'true') if @criterium
    render nothing: true
  end

  def copy_selected
    if @search.criteria.where(selected: true).size > 0
      @search.criteria.where(selected: true).each do |criterium|
        qc_attributes = criterium.copyable_attributes
        qc_attributes[:position] = @search.criteria.size
        qc_attributes[:selected] = false
        @search.criteria.create(qc_attributes)
      end

      @search.update_brackets!
    end
    render 'criteria/criteria'
  end

  def trash_selected
    if @search.criteria.where(selected: true).size > 0
      @search.criteria.where(selected: true).destroy_all
      @search.update_brackets!
    end
    render 'criteria/criteria'
  end

  def indent
    params[:indent] = 0 unless (-2..2).to_a.include?(params[:indent].to_i)
    if @search.criteria.where(selected: true).size > 0
      @search.criteria.where(selected: true).each do |criterium|
        criterium.update_attributes level: [criterium.level + params[:indent].to_i, 0].max
      end

      @search.update_brackets!
    end
    render 'criteria/criteria'
  end

  def right_operator
    @criterium = @search.criteria.find_by_id(params[:criterium_id])
    if @criterium
      @criterium.update_attributes right_operator: params[:right_operator] if Criterium::OPERATOR.include?(params[:right_operator])
      @search.update_brackets!
    end
    render 'criteria/criteria'
  end

  def edit
    @criterium = @search.criteria.find_by_id(params[:id])

    @defaults = { title: @criterium.variable.display_name, width: '100%', make_selection: true, height: '240px', units: '', title: '', legend: 'right' }
    case @criterium.variable.variable_type when 'numeric', 'integer', 'date'
      @defaults[:height] = '300px'
      @defaults[:units] = @criterium.variable.units
      @defaults[:legend] = 'none'
    when 'choices'
      @defaults[:height] = '250px'
    end

    @chart_element_id = "variable_chart_#{@criterium.variable.id}"
    result_hash = @criterium.variable.graph_values(current_user)
    @values = result_hash[:values]
    @categories = result_hash[:categories]

    render nothing: true unless @criterium
  end

  def create
    variable = Variable.current.find_by_id(params[:variable_id])
    @search.criteria << @search.criteria.create(variable_id: variable.id, position: @search.criteria.size) if variable
    @search.reload
    render 'criteria/criteria'
  end

  def update
    @criterium = @search.criteria.find_by_id(params[:id])
    if @criterium
      params[:criterium] = {} if params[:criterium].blank?
      params[:criterium][:right_operator] = 'and' unless Criterium::OPERATOR.include?(params[:criterium][:right_operator])
      if @criterium.variable.variable_type == 'date'
        params[:start_date] = Date.strptime(params[:start_date], "%m/%d/%Y") unless params[:start_date].blank?
        params[:end_date] = Date.strptime(params[:end_date], "%m/%d/%Y") unless params[:end_date].blank?
        params[:criterium][:value] = "#{params[:start_date]}:#{params[:end_date]}"
      elsif params[:values].blank? and @criterium.variable.variable_type == 'choices'
        params[:criterium][:value] = ''
      elsif not params[:values].blank?
        params[:criterium][:value] = params[:values].join(',')
      end
      @criterium.update(criterium_params)
      @search.reload
    end
    render 'criteria/criteria'
  end

  def destroy
    @criterium = @search.criteria.find_by_id(params[:id])
    if @criterium
      @criterium.destroy
      @search.update_brackets!
      @search.reload
    end
    render 'criteria/criteria'
  end

  private

    def criterium_params
      params.require(:criterium).permit(
        :value, :right_operator, :negated, :source_id
      )
    end
end
