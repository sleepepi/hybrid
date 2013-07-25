class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_system_admin, except: [ :index, :settings, :update_settings, :activate ]
  before_action :check_service_account, only: [ :activate ]
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :redirect_without_user, only: [ :show, :edit, :update, :destroy ]

  def settings
  end

  def update_settings
    notifications = {}
    email_settings = ['send_email']
    email_settings.each do |email_setting|
      notifications[email_setting] = (not params[:email].blank? and params[:email][email_setting] == '1')
    end
    current_user.update_attributes email_notifications: notifications
    redirect_to settings_path, notice: 'Email settings saved.'
  end

  def index
    unless current_user.system_admin? or params[:format] == 'json'
      redirect_to root_path, alert: "You do not have sufficient privileges to access that page."
      return
    end

    @order = scrub_order(User, params[:order], 'users.current_sign_in_at DESC')
    @users = User.current.search(params[:search] || params[:q]).order(@order).page(params[:page]).per( 20 )

    respond_to do |format|
      format.html
      format.js
      format.json do # TODO: Put into jbuilder instead!
        render json: @users.collect{ |u| { name: u.name_and_email, id: u.id } }
      end
    end
  end

  def show
  end

  def edit
  end

  # Post /users/activate.json
  def activate
    params[:user] ||= {}
    params[:user][:password] = params[:user][:password_confirmation] = Digest::SHA1.hexdigest(Time.now.usec.to_s)[0..19] if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
    @user = User.new(params.require(:user).permit( :first_name, :last_name, :email, :password, :password_confirmation ))
    if @user.save
      @user.update_column :status, 'active'
      render json: @user, only: [:id, :first_name, :last_name, :email, :status], status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    original_status = @user.status
    if @user.update(params.require(:user).permit( :first_name, :last_name, :email, :system_admin, :service_account, :status ))
      UserMailer.status_activated(@user).deliver if Rails.env.production? and original_status != @user.status and @user.status == 'active'
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: 'User was successfully deleted.'
  end

  private

    def set_user
      @user = User.current.find_by_id(params[:id])
    end

    def redirect_without_user
      empty_response_or_root_path(users_path) unless @user
    end

end
