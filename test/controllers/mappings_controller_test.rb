require 'test_helper'

class MappingsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source = sources(:two)
    @mapping = mappings(:one)
  end

  test "should get automap popup" do
    get :automap_popup, source_id: @source, table: 'table', column: 'column1', format: 'js'
    assert_template 'automap_popup'
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
      post :create, source_id: sources(:two).to_param, concept_id: concepts(:boolean).to_param, table: 'table1', column: 'column3', format: 'js'
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template "create"
  end

  test "should create mapping and show completed mapping" do
    assert_difference('Mapping.count') do
      post :create, source_id: sources(:two).to_param, concept_id: concepts(:datetime).to_param, table: 'table1', column: 'column10', format: 'js'
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template "create"
  end

  test "should not create mapping for invalid source" do
    assert_difference('Mapping.count', 0) do
      post :create, source_id: -1, concept_id: concepts(:datetime).to_param, table: 'table1', column: 'column10', format: 'js'
    end
    assert_nil assigns(:source)
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should show mapping" do
    get :show, source_id: @source, id: @mapping, format: 'js'
    assert_not_nil assigns(:mapping)
    assert_response :success
  end

  test "should not show invalid mapping" do
    get :show, source_id: @source, id: -1, format: 'js'
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mapping, format: 'js'
    assert_response :success
  end

  # TODO: Replace with update_multiple or rewrite update_multiple to just update
  test "should update mapping" do
    patch :update, source_id: sources(:two), id: mappings(:categorical_with_values), mapping: { column_values: [  { column_value: 'm', value: concepts(:boolean_child).to_param, is_null: 'false' },
                                                                                                                  { column_value: '',  value: '',                                is_null: 'true'  },
                                                                                                                  { column_value: '',  value: '',                                is_null: 'false' } ] }, format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template 'show'
  end

  test "should not update mapping with invalid source" do
    patch :update, source_id: -1, id: mappings(:categorical_with_values), mapping: { column_values: [ { column_value: 'm', value: concepts(:boolean_child).to_param, is_null: 'false' },
                                                                                                      { column_value: '',  value: '',                                is_null: 'true'  },
                                                                                                      { column_value: '',  value: '',                                is_null: 'false' } ] }, format: 'js'
    assert_nil assigns(:source)
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should destroy mapping" do
    assert_difference('Mapping.current.count', -1) do
      delete :destroy, source_id: @source, id: @mapping, format: 'js'
    end

    assert_template 'new'
  end

  test "should not destroy mapping without id" do
    assert_difference('Mapping.current.count', 0) do
      delete :destroy, source_id: @source, id: -1, format: 'js'
    end
    assert_nil assigns(:mapping)
    assert_response :success
  end

end
