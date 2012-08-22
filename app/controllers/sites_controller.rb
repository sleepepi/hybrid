class SitesController < ApplicationController
  before_filter :authenticate_user!, only: [:search]
end
