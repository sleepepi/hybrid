require 'test_helper'

class SourceFileTypesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source_file_type = source_file_types(:one)
  end

  test "should get index" do
    get :index, source_id: sources(:two).to_param
    assert_response :success
    assert_not_nil assigns(:source_file_types)
  end

  test "should not get index for invalid source" do
    get :index, source_id: -1
    assert_nil assigns(:source)
    assert_nil assigns(:source_file_types)
    assert_redirected_to root_path
  end

  test "should get new" do
    get :new, source_id: sources(:two).to_param
    assert_response :success
  end

  test "should create source file type" do
    assert_difference('SourceFileType.count') do
      post :create, source_file_type: { file_type_id: file_types(:three).to_param }, source_id: sources(:two).to_param
    end

    assert_redirected_to source_file_type_path(assigns(:source_file_type), source_id: assigns(:source).id)
  end

  test "should not create source file type without valid file type" do
    assert_difference('SourceFileType.count', 0) do
      post :create, source_file_type: { file_type_id: nil }, source_id: sources(:two).to_param
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:source_file_type)
    assert_template 'new'
  end

  test "should not create source file type with invalid source" do
    assert_difference('SourceFileType.count', 0) do
      post :create, source_file_type: { file_type_id: file_types(:three).to_param }, source_id: -1
    end
    assert_nil assigns(:source)
    assert_nil assigns(:source_file_type)
    assert_redirected_to root_path
  end

  test "should show source file type" do
    get :show, id: @source_file_type, source_id: sources(:two).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @source_file_type, source_id: sources(:two).to_param
    assert_response :success
  end

  test "should update source file type" do
    put :update, id: @source_file_type.to_param, source_file_type: { file_type_id: file_types(:four).to_param }, source_id: sources(:two).to_param
    assert_redirected_to source_file_type_path(assigns(:source_file_type), source_id: assigns(:source).id)
  end

  test "should not update source file type with invalid file type" do
    put :update, id: @source_file_type.to_param, source_file_type: { file_type_id: nil }, source_id: sources(:two).to_param
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:source_file_type)
    assert_template 'edit'
  end

  test "should not update source file type with invalid id" do
    put :update, id: -1, source_file_type: { file_type_id: file_types(:four).to_param }, source_id: -1
    assert_nil assigns(:source)
    assert_nil assigns(:source_file_type)
    assert_redirected_to root_path
  end

  test "should destroy source file type" do
    assert_difference('SourceFileType.count', -1) do
      delete :destroy, id: @source_file_type.to_param, source_id: sources(:two).to_param
    end

    assert_not_nil assigns(:source)
    assert_redirected_to source_file_types_path(source_id: assigns(:source).id)
  end

  test "should not destroy source file type with invalid id" do
    assert_difference('SourceFileType.count', 0) do
      delete :destroy, id: -1, source_id: -1
    end

    assert_nil assigns(:source)
    assert_nil assigns(:source_file_type)
    assert_redirected_to root_path
  end
end
