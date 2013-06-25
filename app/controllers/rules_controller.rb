class RulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source,                only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :redirect_without_source,   only: [ :index, :show, :new, :edit, :create, :update, :destroy ]
  before_action :set_rule,                  only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_rule,     only: [ :show, :edit, :update, :destroy ]

  # GET /rules
  # GET /rules.json
  def index
    @order = scrub_order(Rule, params[:order], 'rules.name')
    @rules = @source.rules.order(@order).page(params[:page]).per( 20 )
  end

  # GET /rules/1?source_id=1
  # GET /rules/1.json?source_id=1
  def show
  end

  # GET /rules/new
  def new
    @rule = @source.rules.new
  end

  # GET /rules/1/edit?source_id=1
  def edit
  end

  # POST /rules
  # POST /rules.json
  def create
    @rule = @source.rules.new(rule_params)
    @rule.save
    redirect_to [@rule.source, @rule], notice: 'Rule was successfully created.'
  end

  # PUT /rules/1
  # PUT /rules/1.json
  def update
    @rule.update(rule_params)
    redirect_to [@rule.source, @rule], notice: 'Rule was successfully updated.'
  end

  # DELETE /rules/1
  # DELETE /rules/1.json
  def destroy
    @rule.destroy

    redirect_to source_rules_path(@source), notice: 'Rule was successfully deleted.'
  end

  private

    def set_source
      @source = current_user.all_sources.find_by_id(params[:source_id])
      source = Source.find_by_id(params[:source_id])
      @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    end

    def set_rule
      @rule = @source.rules.find_by_id(params[:id])
    end

    def redirect_without_rule
      empty_response_or_root_path(source_rules_path(@source)) unless @rule
    end

    def rule_params
      params[:rule] ||= {}
      params[:rule][:actions] = params[:rules].blank? ? [] : params[:rules].select{|rule, val| val == '1'}.collect{|rule, val| rule.gsub('_', ' ')}
      params[:rule][:user_tokens] = params[:rule][:user_tokens].to_s
      params[:rule][:blocked] = (params[:rule][:blocked] == '1')

      params.require(:rule).permit(
        :name, :description, :user_tokens, :blocked, { :actions => [] }
      )
    end

end
