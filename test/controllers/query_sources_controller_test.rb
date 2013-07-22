require 'test_helper'

class QuerySourcesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @search = searches(:one)
    @query_source = query_sources(:one)
  end

  test "should create query source" do
    assert_difference('QuerySource.count') do
      post :create, search_id: @search, query_source: { source_id: sources(:three).id }, format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'query_sources'
  end

  test "should not create query source without valid query" do
    assert_difference('QuerySource.count', 0) do
      post :create, search_id: -1, query_source: { source_id: sources(:three).id }, format: 'js'
    end

    assert_nil assigns(:search)
    assert_response :success
  end

  test "should show query source" do
    get :show, search_id: @search, id: @query_source, format: 'js'
    assert_not_nil assigns(:query_source)
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:order)
    assert_template 'sources/popup'
  end

  test "should not show invalid query source" do
    get :show, search_id: @search, id: -1, format: 'js'
    assert_not_nil assigns(:search)
    assert_nil assigns(:query_source)
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should destroy query source" do
    assert_difference('QuerySource.count', -1) do
      delete :destroy, search_id: @search, id: @query_source, format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'query_sources'
  end

  test "should not destroy invalid query source" do
    assert_difference('QuerySource.count', 0) do
      delete :destroy, search_id: @search, id: -1, format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_nil assigns(:query_source)
    assert_response :success
  end
end
