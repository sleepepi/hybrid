class SitesController < ApplicationController
  before_action :authenticate_user!, only: [:search]
end
