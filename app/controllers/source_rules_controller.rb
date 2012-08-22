class SourceRulesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")

    if @source
      @source_rules = @source.source_rules.order('(source_rules.name IS NULL or source_rules.name = ""), source_rules.name, source_rules.id')
    else
      redirect_to root_path
    end
  end

  def show
    source_rule = SourceRule.find_by_id(params[:id])
    @source = current_user.all_sources.find_by_id(source_rule.source_id)
    source = Source.find_by_id(source_rule.source_id)
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    redirect_to root_path, alert: "Source Rule not found." unless @source and @source_rule = @source.source_rules.find_by_id(params[:id])
  end

  def new
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    redirect_to root_path, alert: "You do not have access to this source." unless @source and @source_rule = @source.source_rules.new()
  end

  def edit
    source_rule = SourceRule.find_by_id(params[:id])
    @source = current_user.all_sources.find_by_id(source_rule.source_id)
    source = Source.find_by_id(source_rule.source_id)
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    redirect_to root_path, alert: "Source Rule not found." unless @source and @source_rule = @source.source_rules.find_by_id(params[:id])
  end

  def create
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    if @source
      params[:source_rule] ||= {}
      params[:source_rule][:actions] = params[:rules].blank? ? [] : params[:rules].select{|rule, val| val == '1'}.collect{|rule, val| rule.gsub('_', ' ')}
      params[:source_rule][:user_tokens] = params[:source_rule][:user_tokens].to_s
      params[:source_rule][:blocked] = (params[:source_rule][:blocked] == '1')

      @source_rule = @source.source_rules.new(params[:source_rule])
      @source_rule.save
      redirect_to @source_rule, notice: 'Source Rule was successfully created.'
    else
      redirect_to root_path, alert: "You do not have access to this source."
    end
  end

  def update
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    if @source and @source_rule = @source.source_rules.find_by_id(params[:id])
      params[:source_rule] ||= {}
      params[:source_rule][:actions] = params[:rules].blank? ? [] : params[:rules].select{|rule, val| val == '1'}.collect{|rule, val| rule.gsub('_', ' ')}
      params[:source_rule][:user_tokens] = params[:source_rule][:user_tokens].to_s
      params[:source_rule][:blocked] = (params[:source_rule][:blocked] == '1')

      @source_rule.update_attributes(params[:source_rule])
      redirect_to @source_rule, notice: 'Source Rule was successfully updated.'
    else
      redirect_to root_path, alert: "Source Rule not found."
    end
  end

  def destroy
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source rules")
    if @source and @source_rule = @source.source_rules.find_by_id(params[:id])
      @source_rule.destroy
      redirect_to @source, notice: "Source Rule Deleted."
    else
      redirect_to root_path, alert: "Source Rule not found."
    end
  end
end
