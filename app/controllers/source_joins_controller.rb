class SourceJoinsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_system_admin

  # TODO Make SourceJoins available to user with appropriate source_rules.

  def index
    @source = current_user.all_sources.find_by_id(params[:source_id])
    source = Source.find_by_id(params[:source_id])
    @source = source if (not @source) and source and source.user_has_action?(current_user, "edit data source mappings")

    # current_user.update_attribute :source_joins_per_page, params[:source_joins_per_page].to_i if params[:source_joins_per_page].to_i >= 10 and params[:source_joins_per_page].to_i <= 200
    @order = params[:order].blank? ? 'source_joins.source_id' : params[:order]
    source_join_scope = SourceJoin.current
    source_join_scope = source_join_scope.with_source(@source.id) if @source
    @search_terms = params[:search].to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| source_join_scope = source_join_scope.search(search_term) }
    source_join_scope = source_join_scope.order(@order)
    @source_joins = source_join_scope.page(params[:page]).per(20) #(current_user.source_joins_per_page)
  end

  def show
    @source_join = SourceJoin.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @source_join }
    end
  end

  def new
    @source_join = SourceJoin.new({ source_id: params[:source_id] })
  end

  def edit
    @source_join = SourceJoin.find(params[:id])
  end

  def create
    @source_join = SourceJoin.new(params[:source_join])

    if @source_join.save
      redirect_to(@source_join, notice: 'Join was successfully created.')
    else
      render action: "new"
    end
  end

  def update
    @source_join = SourceJoin.find(params[:id])

    if @source_join.update_attributes(params[:source_join])
      redirect_to(@source_join, notice: 'Join was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    @source_join = SourceJoin.find(params[:id])
    @source_join.destroy

    redirect_to(source_joins_url)
  end
end
