require 'test_helper'

class MappingsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @mapping = mappings(:one)
  end

  test "should get info for categorical concept" do
    post :info, id: mappings(:categorical_with_values).to_param, format: 'js'

    assert_not_nil assigns(:mapping)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)

    assert_template 'info'
  end

  test "should get info for continuous concept" do
    post :info, id: mappings(:continuous_with_units).to_param, format: 'js'

    assert_not_nil assigns(:mapping)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)

    assert_template 'info'
  end

  test "should get info and render blank without concept" do
    post :info, id: -1, format: 'js'
    assert_nil assigns(:concept)
    assert_response :success
  end

  test "should search available concepts" do
    post :search_available, source_id: sources(:two).to_param, term: 'gender', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:search_terms)
    assert_not_nil assigns(:concepts)
    assert_template 'search_available'
  end

  test "empty search should search available concepts and return no concepts" do
    post :search_available, source_id: sources(:two).to_param, term: '', format: 'js'
    assert_not_nil assigns(:source)
    assert_equal [], assigns(:search_terms)
    assert_equal [], assigns(:concepts)
    assert_template 'search_available'
  end

  test "should get expanded for categorical concept" do
    post :expanded, id: mappings(:categorical_with_values).to_param, format: 'js'

    assert_not_nil assigns(:mapping)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)

    assert_template 'expanded'
  end

  test "should get expanded for continuous concept" do
    post :expanded, id: mappings(:continuous_with_units).to_param, format: 'js'

    assert_not_nil assigns(:mapping)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)

    assert_template 'expanded'
  end

  test "should get expanded and render blank without concept" do
    post :expanded, id: -1, format: 'js'
    assert_nil assigns(:mapping)
    assert_response :success
  end

  # # TODO: Remove/rewrite, no index action.
  # test "should get index" do
  #   get :index
  #   assert_response :success
  #   assert_not_nil assigns(:mappings)
  # end

  # # TODO: Remove/rewrite, no new action.
  # test "should get new" do
  #   get :new
  #   assert_response :success
  # end

  test "should create mapping and show additional options to complete mapping" do
    assert_difference('Mapping.count') do
      post :create, source_id: sources(:two).to_param, new_concept_id: concepts(:boolean).to_param, table: 'table1', column: 'column3'
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template "edit"
  end

  test "should create mapping and show completed mapping" do
    assert_difference('Mapping.count') do
      post :create, source_id: sources(:two).to_param, new_concept_id: concepts(:datetime).to_param, table: 'table1', column: 'column10'
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template "show"
  end

  test "should not create mapping for invalid source" do
    assert_difference('Mapping.count', 0) do
      post :create, source_id: -1, new_concept_id: concepts(:datetime).to_param, table: 'table1', column: 'column10'
    end
    assert_nil assigns(:source)
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should show mapping" do
    get :show, id: @mapping.to_param
    assert_not_nil assigns(:mapping)
    assert_response :success
  end

  test "should not show invalid mapping" do
    get :show, id: -1
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mapping.to_param
    assert_response :success
  end

  # TODO: Replace with update_multiple or rewrite update_multiple to just update
  test "should update multiple mappings" do
    post :update_multiple, source_id: sources(:two).to_param, selected_mapping_id: mappings(:categorical_with_values).to_param, mappings: {mappings(:categorical_with_values).to_param => {mapping_column_values: [['value_m', {value: concepts(:boolean_child).to_param, is_null: 'false'}],['value_', {value: '', is_null: 'true'}],['value_&lt;&#33;&#91;CDATA&#91;&#93;&#93;&gt;', {value: "", is_null: 'false'}]]}}, table: 'table', column: 'gender', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mappings)
    assert_template 'update_multiple'
  end

  test "update multiple mappings should render nothing if source not specified" do
    post :update_multiple, source_id: -1, selected_mapping_id: mappings(:categorical_with_values).to_param, mappings: {mappings(:categorical_with_values).to_param => {mapping_column_values: [['value_m', {value: concepts(:boolean_child).to_param, is_null: 'false'}],['value_', {value: '', is_null: 'true'}]]}}, table: 'table', column: 'gender', format: 'js'
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should destroy mapping" do
    assert_difference('Mapping.current.count', -1) do
      delete :destroy, id: @mapping.to_param
    end

    assert_template "new"
  end

  test "should not destroy mapping without id" do
    assert_difference('Mapping.current.count', 0) do
      delete :destroy, id: -1
    end
    assert_nil assigns(:mapping)
    assert_response :success
  end

end
