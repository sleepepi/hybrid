class VariablesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_viewable_dictionary,     only: [ :index, :show ]
  before_action :redirect_without_dictionary, only: [ :index, :show ]
  before_action :set_variable,                only: [ :show ]
  before_action :redirect_without_variable,   only: [ :show ]

  # GET /variables
  # GET /variables.json
  def index
    @order = scrub_order(Variable, params[:order], "variables.folder, variables.name")
    @variables = @dictionary.variables.search(params[:search]).order(@order).page(params[:page]).per( 20 )
  end

  # GET /variables/1
  # GET /variables/1.json
  def show
  end

  private

    def set_variable
      @variable = @dictionary.variables.find_by_id(params[:id])
    end

    def redirect_without_variable
      empty_response_or_root_path(dictionary_variables_path(@dictionary)) unless @variable
    end

end
