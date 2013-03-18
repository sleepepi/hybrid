require 'test_helper'

SimpleCov.command_name "test:controllers"

class UsersControllerTest < ActionController::TestCase
  setup do
    @current_user = login(users(:admin))
    @user = users(:valid)
  end

  test "should create and activate user" do
    login(users(:service_account))
    assert_difference('User.count') do
      post :activate, user: { first_name: 'New First Name', last_name: 'New Last Name', email: 'new_activated_user@example.com' }, format: 'json'
    end
    assert_not_nil assigns(:user)
    assert_equal "New First Name", assigns(:user).first_name
    assert_equal "New Last Name", assigns(:user).last_name
    assert_equal 'new_activated_user@example.com', assigns(:user).email
    assert_equal 'active', assigns(:user).status
  end

  test "should not create and activate user with missing parameters" do
    login(users(:service_account))
    assert_difference('User.count', 0) do
      post :activate, user: { first_name: '', last_name: 'New Last Name', email: 'new_activated_user@example.com' }, format: 'json'
    end
    assert_not_nil assigns(:user)
    assert_equal "", assigns(:user).first_name
    assert_equal "New Last Name", assigns(:user).last_name
    assert_equal 'new_activated_user@example.com', assigns(:user).email
    assert_equal 'pending', assigns(:user).status
    assert_equal 1, assigns(:user).errors.size
    assert_response :unprocessable_entity
  end

  test "should not create and activate user without service account" do
    login(users(:valid))
    assert_difference('User.count', 0) do
      post :activate, user: { first_name: '', last_name: 'New Last Name', email: 'new_activated_user@example.com' }, format: 'json'
    end
    assert_nil assigns(:user)

    object = JSON.parse(@response.body)
    assert_equal 'Only Service Accounts have access to this web service. Make sure your account is properly flagged as a service account.', object['error']
    assert_response :success
  end

  test "should update settings and enable email" do
    post :update_settings, id: users(:admin), email: { send_email: '1' }
    users(:admin).reload # Needs reload to avoid stale object
    assert_equal true, users(:admin).email_on?(:send_email)
    assert_equal 'Email settings saved.', flash[:notice]
    assert_redirected_to settings_path
  end

  test "should update settings and disable email" do
    post :update_settings, id: users(:admin), email: { send_email: '0' }
    users(:admin).reload # Needs reload to avoid stale object
    assert_equal false, users(:admin).email_on?(:send_email)
    assert_equal 'Email settings saved.', flash[:notice]
    assert_redirected_to settings_path
  end

  test "should get index" do
    get :index
    assert_not_nil assigns(:users)
    assert_response :success
  end

  test "should get index with pagination" do
    get :index, format: 'js'
    assert_not_nil assigns(:users)
    assert_template 'index'
  end

  test "should get index for autocomplete" do
    login(users(:valid))
    get :index, format: 'json'
    assert_not_nil assigns(:users)
    assert_response :success
  end

  test "should not get index for non-system admin" do
    login(users(:valid))
    get :index
    assert_nil assigns(:users)
    assert_equal "You do not have sufficient privileges to access that page.", flash[:alert]
    assert_redirected_to root_path
  end

  test "should not get index with pagination for non-system admin" do
    login(users(:valid))
    get :index, format: 'js'
    assert_nil assigns(:users)
    assert_equal "You do not have sufficient privileges to access that page.", flash[:alert]
    assert_redirected_to root_path
  end

  # test "should get new" do
  #   get :new
  #   assert_response :success
  # end

  # test "should create user" do
  #   assert_difference('User.count') do
  #     post :create, user: @user.attributes
  #   end
  #
  #   assert_redirected_to user_path(assigns(:user))
  # end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    put :update, id: @user, user: @user.attributes
    assert_redirected_to user_path(assigns(:user))
  end

  test "should update user and set user active" do
    put :update, id: users(:pending), user: { status: 'active', first_name: users(:pending).first_name, last_name: users(:pending).last_name, email: users(:pending).email, system_admin: false }
    assert_equal 'active', assigns(:user).status
    assert_redirected_to user_path(assigns(:user))
  end

  test "should update user and set user inactive" do
    put :update, id: users(:pending), user: { status: 'inactive', first_name: users(:pending).first_name, last_name: users(:pending).last_name, email: users(:pending).email, system_admin: false }
    assert_equal 'inactive', assigns(:user).status
    assert_redirected_to user_path(assigns(:user))
  end

  test "should not update user with blank name" do
    put :update, id: @user, user: { first_name: '', last_name: '' }
    assert_not_nil assigns(:user)
    assert_template 'edit'
  end

  test "should destroy user" do
    assert_difference('User.current.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
