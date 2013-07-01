class DomainsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_viewable_dictionary,     only: [ :index, :show ]
  before_action :redirect_without_dictionary, only: [ :index, :show ]
  before_action :set_domain,                  only: [ :show ]
  before_action :redirect_without_domain,     only: [ :show ]

  # GET /dictionaries/1/domains
  # GET /dictionaries/1/domains.json
  def index
    @order = scrub_order(Domain, params[:order], "domains.name")
    @domains = @dictionary.domains.search(params[:search]).order(@order).page(params[:page]).per( 20 )
  end

  # GET /dictionaries/1/domains/1
  # GET /dictionaries/1/domains/1.json
  def show
  end

  private

    def set_domain
      @domain = @dictionary.domains.current.find(params[:id])
    end

    def redirect_without_domain
      empty_response_or_root_path(dictionary_domains_path(@dictionary)) unless @domain
    end

end
