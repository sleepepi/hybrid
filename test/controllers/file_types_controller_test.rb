require 'test_helper'

class FileTypesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @file_type = file_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:file_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create file type" do
    assert_difference('FileType.count') do
      post :create, file_type: @file_type.attributes
    end

    assert_not_nil assigns(:file_type)
    assert_redirected_to file_type_path(assigns(:file_type))
  end

  test "should not create file type with invalid attributes" do
    assert_difference('FileType.count', 0) do
      post :create, file_type: { name: '', extension: '' }
    end
    assert_not_nil assigns(:file_type)
    assert_template 'new'
  end

  test "should show file type" do
    get :show, id: @file_type.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @file_type.to_param
    assert_response :success
  end

  test "should update file type" do
    put :update, id: @file_type.to_param, file_type: @file_type.attributes
    assert_redirected_to file_type_path(assigns(:file_type))
  end

  test "should not update file type with invalid attributes" do
    put :update, id: @file_type.to_param, file_type: { name: '', extension: '' }
    assert_not_nil assigns(:file_type)
    assert assigns(:file_type).errors.size > 0
    assert_template 'edit'
  end

  test "should not update invalid file type" do
    put :update, id: -1, file_type: @file_type.attributes
    assert_nil assigns(:file_type)
    assert_redirected_to file_types_path
  end

  test "should destroy file type" do
    assert_difference('FileType.count', -1) do
      delete :destroy, id: @file_type.to_param
    end

    assert_redirected_to file_types_path
  end

  test "should not destroy invalid file type" do
    assert_difference('FileType.count', 0) do
      delete :destroy, id: -1
    end
    assert_nil assigns(:file_type)
    assert_redirected_to file_types_path
  end
end
