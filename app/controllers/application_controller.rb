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

  def parse_date(date_string, default_date = '')
    date_string.to_s.split('/').last.size == 2 ? Date.strptime(date_string, "%m/%d/%y") : Date.strptime(date_string, "%m/%d/%Y") rescue default_date
  end

  def scrub_order(model, params_order, default_order)
    (params_column, params_direction) = params_order.to_s.strip.downcase.split(' ')
    direction = (params_direction == 'desc' ? 'DESC' : nil)
    column_name = (model.column_names.collect{|c| model.table_name + "." + c}.select{|c| c == params_column}.first)
    order = column_name.blank? ? default_order : [column_name, direction].compact.join(' ')
    order
  end
end
