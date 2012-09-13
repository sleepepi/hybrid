class DictionariesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_system_admin

  def remove_concepts_and_relations
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    if @dictionary
      @dictionary.cleanup('')
      redirect_to @dictionary
    else
      redirect_to root_path
    end
  end

  def index
    # current_user.update_column :users_per_page, params[:users_per_page].to_i if params[:users_per_page].to_i >= 10 and params[:users_per_page].to_i <= 200
    dictionary_scope = Dictionary.current
    @search_terms = params[:search].to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| dictionary_scope = dictionary_scope.search(search_term) }

    @order = scrub_order(Dictionary, params[:order], 'dictionaries.name')
    dictionary_scope = dictionary_scope.order(@order)

    @dictionaries = dictionary_scope.page(params[:page]).per(20) #(current_user.users_per_page)
  end

  def show
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    redirect_to root_path unless @dictionary
  end

  def new
    @dictionary = current_user.dictionaries.new
  end

  def edit
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    redirect_to root_path unless @dictionary
  end

  def create
    @dictionary = current_user.dictionaries.new(params[:dictionary])

    if @dictionary.save
      unless params[:dictionary_file].blank?
        if params[:dictionary_file].original_filename =~ /.*\.csv/i
          @dictionary.import_csv(params[:dictionary_file].tempfile.path)
        else
          flash[:alert] = "Unsupported dictionary file format!"
        end
      end
      redirect_to(@dictionary, notice: 'Dictionary was successfully created.')
    else
      render action: "new"
    end
  end

  def update
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])

    unless @dictionary
      redirect_to root_path
      return
    end

    if @dictionary.update_attributes(params[:dictionary])
      unless params[:dictionary_file].blank?
        if params[:dictionary_file].original_filename =~ /.*\.csv/i
          @dictionary.import_csv(params[:dictionary_file].tempfile.path)
        else
          flash[:alert] = "Unsupported dictionary file format!"
        end
      end

      redirect_to(@dictionary, notice: 'Dictionary was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    if @dictionary
      @dictionary.destroy
      redirect_to dictionaries_path
    else
      redirect_to root_path
    end
  end

  def export_to_csv
    @dictionary = current_user.all_dictionaries.find_by_id(params[:id])
    if @dictionary
      send_data @dictionary.export_csv,
                type: 'text/csv; charset=iso-8859-1; header=present',
                disposition: "attachment; filename=\"#{@dictionary.name.gsub(/[^\w]/, '')} #{Time.now.strftime("%Y.%m.%d %Ih%M %p")}.csv\""
    else
      render nothing: true
    end
  end
end
