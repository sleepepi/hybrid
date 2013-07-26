class SearchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search,               only: [ :autocomplete, :destroy, :variables_popup, :open_folder, :edit, :update, :undo, :redo, :total_records_count, :reorder ]
  before_action :redirect_without_search,  only: [ :autocomplete, :destroy, :variables_popup, :open_folder, :edit, :update, :undo, :redo, :total_records_count, :reorder ]

  # GET /searches/1/variable_popup.js
  def variables_popup

  end

  # GET /searches/1/open_folder.js
  def open_folder

  end

  def autocomplete
    @variables = Variable.current.search(params[:search]).where( dictionary_id: @search.sources.collect{|s| s.all_linked_sources_and_self}.flatten.uniq.collect{|s| s.variables.pluck(:dictionary_id).uniq}.flatten.uniq ).page(params[:page]).per(10)
    render json: @variables.group_by{|v| v.folder}.collect{|folder, variables| { text: folder, commonly_used: true, children: variables.collect{|v| { id: v.id, text: v.display_name, commonly_used: v.commonly_used }}}}
  end

  # Get Count
  def total_records_count
    total_records_found = 0
    @overall_totals = {}
    @overall_errors = {}

    if @search.sources.size == 0
      @sql_conditions = []
      @overall_totals[nil] = []
      @overall_errors[nil] = 'No Data Sources Selected'
    else
      sub_totals = []

      @search.sources.each do |source|
        if source.user_has_action?(current_user, 'get count') or current_user.all_sources.include?(source)
          sub_totals << @search.record_count_only_with_sub_totals_using_resolvers(current_user, source, @search.criteria)
        else
          # sub_totals << { result: [[nil, 0]], errors: [[nil, "No permissions to get counts for #{source.name}"]] }
        end
      end

      @sql_conditions = sub_totals.collect{|st| st[:sql_conditions]}.flatten

      sub_totals.each do |sub_total_hash|
        sub_total = sub_total_hash[:result]
        sub_total_error = sub_total_hash[:errors]

        sub_total.each do |grouping, total|
          @overall_totals[grouping] ||= []
          @overall_totals[grouping] = @overall_totals[grouping] + total
        end

        sub_total_error.each do |grouping, total|
          @overall_errors[grouping] = [@overall_errors[grouping], "#{total}"].select{|i| not i.blank?}.join(', ')
        end
      end

      @search.update( total: (@overall_totals[nil].first[:count] rescue 0) )
    end
  end

  def reorder
    criterium_ids = params[:order].to_s.gsub('criterium_', '').split(',').select{|i| not i.blank?}
    @search.reorder(criterium_ids)
    render 'criteria/criteria'
  end

  def data_files
    @file_type = FileType.find_by_id(params[:file_type_id])
    @search = current_user.searches.find_by_id(params[:id])
    render nothing: true unless @search
  end

  def load_file_type
    @file_type = FileType.find_by_id(params[:file_type_id])
    @search = current_user.searches.find_by_id(params[:id])
    render nothing: true unless @search
  end

  # GET /searches/1/edit.js
  def edit
  end

  # POST /searches/1.js
  def update
    @search.reload unless @search.update search_params
    render 'show'
  end

  def undo
    @search.undo!
    render 'criteria/criteria'
  end

  def redo
    @search.redo!
    render 'criteria/criteria'
  end

  def index
    @order = scrub_order(Search, params[:order], 'searches.created_at DESC')
    @searches = current_user.all_searches.search(params[:search]).order(@order).page(params[:page]).per(20)
  end

  def show
    @search = current_user.all_searches.find_by_id(params[:id])
    @search = current_user.all_searches.find_by_id(current_user.current_search_id) unless @search
    @search = current_user.searches.create(name: "#{current_user.last_name} ##{current_user.searches.count+1}") unless @search

    current_user.update_column :current_search_id, @search.id
  end

  def new
    @search = current_user.searches.create(name: "#{current_user.last_name} ##{current_user.searches.count+1}")
    current_user.update_column :current_search_id, @search.id
    redirect_to root_path, notice: "Created search #{@search.name}"
  end

  def copy
    @original_search = current_user.all_searches.find_by_id(params[:id])
    if @original_search
      @search = @original_search.copy
      current_user.update_column :current_search_id, @search.id
      redirect_to root_path, notice: "Copied search #{@original_search.name}"
    else
      redirect_to root_path, alert: "You do not have access to that search"
    end
  end

  # # POST /searches
  # # POST /searches.xml
  # def create
  #   @search = Search.new(params[:search])
  #
  #   respond_to do |format|
  #     if @search.save
  #       format.html { redirect_to(@search, notice: 'Search was successfully created.') }
  #       format.xml  { render xml: @search, status: :created, location: @search }
  #     else
  #       format.html { render action: "new" }
  #       format.xml  { render xml: @search.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # # PUT /searches/1
  # # PUT /searches/1.xml
  # def update
  #   @search = Search.find(params[:id])
  #
  #   respond_to do |format|
  #     if @search.update_attributes(params[:search])
  #       format.html { redirect_to(@search, notice: 'Search was successfully updated.') }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render action: "edit" }
  #       format.xml  { render xml: @search.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  def destroy
    @search.destroy
    redirect_to searches_path
  end

  private

    def set_search
      super(:id)
    end

    def search_params
      params.require(:search).permit(
        :name
      )
    end


end
