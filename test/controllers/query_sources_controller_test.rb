require 'test_helper'

class QuerySourcesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @query = queries(:one)
    @query_source = query_sources(:one)
  end

  test "should create query source" do
    assert_difference('QuerySource.count') do
      post :create, query_id: @query, query_source: { source_id: sources(:three).id }, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_sources'
  end

  test "should not create query source without valid query" do
    assert_difference('QuerySource.count', 0) do
      post :create, query_id: -1, query_source: { source_id: sources(:three).id }, format: 'js'
    end

    assert_nil assigns(:query)
    assert_response :success
  end

  test "should show query source" do
    get :show, query_id: @query, id: @query_source, format: 'js'
    assert_not_nil assigns(:query_source)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:order)
    assert_template 'sources/popup'
  end

  test "should not show invalid query source" do
    get :show, query_id: @query, id: -1, format: 'js'
    assert_not_nil assigns(:query)
    assert_nil assigns(:query_source)
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should destroy query source" do
    assert_difference('QuerySource.count', -1) do
      delete :destroy, query_id: @query, id: @query_source, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_sources'
  end

  test "should not destroy invalid query source" do
    assert_difference('QuerySource.count', 0) do
      delete :destroy, query_id: @query, id: -1, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_nil assigns(:query_source)
    assert_response :success
  end
end
