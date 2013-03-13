class DictionariesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin
  before_action :set_dictionary, only: [ :show, :edit, :update, :destroy, :remove_concepts_and_relations, :export_to_csv ]
  before_action :redirect_without_dictionary, only: [ :show, :edit, :update, :destroy, :remove_concepts_and_relations, :export_to_csv ]

  def remove_concepts_and_relations
    @dictionary.cleanup('')
    redirect_to @dictionary
  end

  def export_to_csv
    send_data @dictionary.export_csv,
      type: 'text/csv; charset=iso-8859-1; header=present',
      disposition: "attachment; filename=\"#{@dictionary.name.gsub(/[^\w]/, '')} #{Time.now.strftime("%Y.%m.%d %Ih%M %p")}.csv\""
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
      unless params[:dictionary_file].blank?
        if params[:dictionary_file].original_filename =~ /.*\.csv/i
          @dictionary.import_csv(params[:dictionary_file].tempfile.path)
        else
          flash[:alert] = "Unsupported dictionary file format!"
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
      unless params[:dictionary_file].blank?
        if params[:dictionary_file].original_filename =~ /.*\.csv/i
          @dictionary.import_csv(params[:dictionary_file].tempfile.path)
        else
          flash[:alert] = "Unsupported dictionary file format!"
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

    def set_dictionary
      @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    end

    def redirect_without_dictionary
      empty_response_or_root_path(dictionaries_path) unless @dictionary
    end

    def dictionary_params
      params.require(:dictionary).permit(
        :name, :description, :visible, :status
      )
    end
end
