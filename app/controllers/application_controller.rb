class ApplicationController < ActionController::Base
  protect_from_forgery

  layout "contour/layouts/application"

  protected

  def check_system_admin
    redirect_to root_path, alert: "You do not have sufficient privileges to access that page." unless current_user.system_admin?
  end

  def check_service_account
    unless current_user.service_account?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "You do not have sufficient privileges to access that page." }
        format.json { render json: { error: 'Only Service Accounts have access to this web service. Make sure your account is properly flagged as a service account.'} }
      end
    end
  end
end
