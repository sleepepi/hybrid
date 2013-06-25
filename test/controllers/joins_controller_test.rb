require 'test_helper'

class JoinsControllerTest < ActionController::TestCase
  setup do
    login(users(:valid))
    @source = sources(:one)
    @join = joins(:one)
  end

  test "should get index" do
    get :index, source_id: @source
    assert_response :success
    assert_not_nil assigns(:joins)
  end

  test "should not get index with invalid source" do
    get :index, source_id: -1
    assert_nil assigns(:joins)
    assert_redirected_to root_path
  end

  test "should get new" do
    get :new, source_id: @source
    assert_response :success
  end

  test "should create source join" do
    assert_difference('Join.count') do
      post :create, source_id: @source, join: { from_table: 'table1', from_column: 'id', to_table: 'table2', to_column: 't1_id' }
    end

    assert_redirected_to source_join_path(assigns(:join).source, assigns(:join))
  end

  test "should not create source join with blank parameters" do
    assert_difference('Join.count', 0) do
      post :create, source_id: @source, join: { from_table: '', from_column: '', to_table: '', to_column: '' }
    end

    assert_not_nil assigns(:join)
    assert_template 'new'
  end

  test "should show source join" do
    get :show, id: @join, source_id: @source
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @join, source_id: @source
    assert_response :success
  end

  test "should update source join" do
    put :update, id: @join, source_id: @source, join: { from_table: 'table1', from_column: 'id', to_table: 'table2', to_column: 't1_id' }
    assert_redirected_to source_join_path(assigns(:join).source, assigns(:join))
  end

  test "should not update source join with blank parameters" do
    put :update, id: @join, source_id: @source, join: { from_table: '', from_column: '', to_table: '', to_column: '' }
    assert_not_nil assigns(:join)
    assert_template 'edit'
  end

  test "should destroy source join" do
    assert_difference('Join.count', -1) do
      delete :destroy, id: @join, source_id: @source
    end

    assert_redirected_to source_joins_path
  end

  test "should not destroy invalid source join" do
    assert_difference('Join.count', 0) do
      delete :destroy, id: -1, source_id: @source
    end

    assert_redirected_to source_joins_path
  end
end
