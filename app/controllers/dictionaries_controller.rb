class DictionariesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin
  before_action :set_editable_dictionary,     only: [ :show, :edit, :update, :destroy, :clean ]
  before_action :redirect_without_dictionary, only: [ :show, :edit, :update, :destroy, :clean ]

  # POST /dictionaries/1/clean
  def clean
    @dictionary.clean
    redirect_to @dictionary
  end

  # GET /dictionaries
  # GET /dictionaries.json
  def index
    @order = scrub_order(Dictionary, params[:order], 'dictionaries.name')
    @dictionaries = Dictionary.current.search(params[:search]).order(@order).page(params[:page]).per(20)
  end

  # GET /dictionaries/1
  # GET /dictionaries/1.json
  def show
  end

  # GET /dictionaries/new
  def new
    @dictionary = current_user.dictionaries.new
  end

  # GET /dictionaries/1/edit
  def edit
  end

  # POST /dictionaries
  # POST /dictionaries.json
  def create
    @dictionary = current_user.dictionaries.new(dictionary_params)

    if @dictionary.save
      unless params[:domains_file].blank?
        if params[:domains_file].original_filename =~ /.*\.csv/i
          @dictionary.import_domains(params[:domains_file].tempfile.path)
        else
          flash[:alert] = "Unsupported domains file format!"
        end
      end

      unless params[:variables_file].blank?
        if params[:variables_file].original_filename =~ /.*\.csv/i
          @dictionary.import_variables(params[:variables_file].tempfile.path)
        else
          flash[:alert] = "Unsupported variables file format!"
        end
      end

      redirect_to @dictionary, notice: 'Dictionary was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /dictionaries/1
  # PUT /dictionaries/1.json
  def update
    if @dictionary.update(dictionary_params)
      unless params[:domains_file].blank?
        if params[:domains_file].original_filename =~ /.*\.csv/i
          @dictionary.import_domains(params[:domains_file].tempfile.path)
        else
          flash[:alert] = "Unsupported domains file format!"
        end
      end

      unless params[:variables_file].blank?
        if params[:variables_file].original_filename =~ /.*\.csv/i
          @dictionary.import_variables(params[:variables_file].tempfile.path)
        else
          flash[:alert] = "Unsupported variables file format!"
        end
      end

      redirect_to(@dictionary, notice: 'Dictionary was successfully updated.')
    else
      render action: 'edit'
    end
  end

  # DELETE /dictionaries/1
  # DELETE /dictionaries/1.json
  def destroy
    @dictionary.destroy

    respond_to do |format|
      format.html { redirect_to dictionaries_path }
      format.json { head :no_content }
    end
  end

  private

    def set_editable_dictionary
      super(:id)
    end

    def dictionary_params
      params.require(:dictionary).permit(
        :name, :description, :visible
      )
    end
end
