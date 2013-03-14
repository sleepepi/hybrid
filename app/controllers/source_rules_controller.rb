class SourceRulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source,                    only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :redirect_without_source,       only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :set_source_rule,               only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_source_rule,  only: [ :show, :edit, :update, :destroy ]

  # GET /source_rules
  # GET /source_rules.json
  def index
    @order = scrub_order(SourceRule, params[:order], 'source_rules.name')
    @source_rules = @source.source_rules.order(@order).page(params[:page]).per( 20 )
  end

  # GET /source_rules/1?source_id=1
  # GET /source_rules/1.json?source_id=1
  def show
  end

  # GET /source_rules/new
  def new
    @source_rule = @source.source_rules.new
  end

  # GET /source_rules/1/edit?source_id=1
  def edit
  end

  # POST /source_rules
  # POST /source_rules.json
  def create
    @source_rule = @source.source_rules.new(source_rule_params)
    @source_rule.save
    redirect_to source_rule_path(@source_rule, source_id: @source.id), notice: 'Source rule was successfully created.'
  end

  # PUT /source_rules/1
  # PUT /source_rules/1.json
  def update
    @source_rule.update(source_rule_params)
    redirect_to source_rule_path(@source_rule, source_id: @source.id), notice: 'Source rule was successfully updated.'
  end

  # DELETE /source_rules/1
  # DELETE /source_rules/1.json
  def destroy
    @source_rule.destroy
    redirect_to source_rules_path(source_id: @source.id), notice: 'Source rule was successfully deleted.'
  end

  private

    def set_source
      @source = current_user.all_sources.find_by_id(params[:source_id])
      source = Source.find_by_id(params[:source_id])
      @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    end

    def redirect_without_source
      empty_response_or_root_path unless @source
    end

    def set_source_rule
      @source_rule = @source.source_rules.find_by_id(params[:id])
    end

    def redirect_without_source_rule
      empty_response_or_root_path(source_rules_path(source_id: @source.id)) unless @source_rule
    end

    def source_rule_params
      params[:source_rule] ||= {}
      params[:source_rule][:actions] = params[:rules].blank? ? [] : params[:rules].select{|rule, val| val == '1'}.collect{|rule, val| rule.gsub('_', ' ')}
      params[:source_rule][:user_tokens] = params[:source_rule][:user_tokens].to_s
      params[:source_rule][:blocked] = (params[:source_rule][:blocked] == '1')

      params.require(:source_rule).permit(
        :name, :description, :user_tokens, :blocked, { :actions => [] }
      )
    end

end
