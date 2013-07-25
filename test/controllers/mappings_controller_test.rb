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

  test "should get info for choices variable" do
    post :info, source_id: @source, id: mappings(:choices_with_values), format: 'js'

    assert_not_nil assigns(:mapping)
    assert_template 'info'
  end

  test "should get info for continuous variable" do
    post :info, source_id: @source, id: mappings(:numeric_with_units).to_param, format: 'js'

    assert_not_nil assigns(:mapping)

    assert_template 'info'
  end

  test "should get info and render blank without variable" do
    post :info, source_id: @source, id: -1, format: 'js'
    assert_nil assigns(:mapping)
    assert_response :success
  end

  test "should create mapping and show completed mapping" do
    assert_difference('Mapping.count') do
      post :create, source_id: @source.id, mapping: { variable_id: variables(:date).id, table: 'table1', column: 'column10' }, format: 'js'
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:mapping)
    assert_template 'show'
  end

  test "should not create mapping for invalid source" do
    assert_difference('Mapping.count', 0) do
      post :create, source_id: -1, mapping: { variable_id: variables(:date).id, table: 'table1', column: 'column10' }, format: 'js'
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
