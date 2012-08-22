require 'test_helper'

class QuerySourcesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @query_source = query_sources(:one)
  end

  test "should create query source" do
    assert_difference('QuerySource.count') do
      post :create, query_source: @query_source.attributes, query_id: queries(:one).to_param, selected_source_id: sources(:three).to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_sources'
  end

  test "should not create query source without valid query" do
    assert_difference('QuerySource.count', 0) do
      post :create, query_source: @query_source.attributes, query_id: -1, selected_source_id: sources(:three).to_param, format: 'js'
    end

    assert_nil assigns(:query)
    assert_response :success
  end

  test "should show query source" do
    get :show, id: @query_source.to_param, format: 'js'
    assert_not_nil assigns(:query_source)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:order)
    assert_template 'show'
  end

  test "should not show invalid query source" do
    get :show, id: -1, format: 'js'
    assert_nil assigns(:query_source)
    assert_nil assigns(:query)
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should destroy query source" do
    assert_difference('QuerySource.count', -1) do
      delete :destroy, id: @query_source.to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_sources'
  end

  test "should not destroy invalid query source" do
    assert_difference('QuerySource.count', 0) do
      delete :destroy, id: -1, format: 'js'
    end

    assert_nil assigns(:query_source)
    assert_nil assigns(:query)
    assert_response :success
  end
end
