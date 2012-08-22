require 'test_helper'

class SourceJoinsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source_join = source_joins(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:source_joins)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create source join" do
    assert_difference('SourceJoin.count') do
      post :create, source_join: @source_join.attributes
    end

    assert_redirected_to source_join_path(assigns(:source_join))
  end

  test "should not create source join with blank parameters" do
    assert_difference('SourceJoin.count', 0) do
      post :create, source_join: {}
    end

    assert_not_nil assigns(:source_join)
    assert_template 'new'
  end

  test "should show source join" do
    get :show, id: @source_join.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @source_join.to_param
    assert_response :success
  end

  test "should update source join" do
    put :update, id: @source_join.to_param, source_join: @source_join.attributes
    assert_redirected_to source_join_path(assigns(:source_join))
  end

  test "should not update source join with blank parameters" do
    put :update, id: @source_join.to_param, source_join: { source_id: nil }
    assert_not_nil assigns(:source_join)
    assert_template 'edit'
  end

  test "should destroy source join" do
    assert_difference('SourceJoin.count', -1) do
      delete :destroy, id: @source_join.to_param
    end

    assert_redirected_to source_joins_path
  end
end
