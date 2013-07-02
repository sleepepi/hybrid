require 'test_helper'

class MatchingControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
  end

  test "get matching" do
    get :matching, controls_id: queries(:query_with_test_data).id, cases_id: queries(:query_with_test_data).id #, format: 'js'
    assert_not_nil assigns(:controls)
    assert_not_nil assigns(:cases)
    assert_equal 1, assigns(:controls_per_case)
    assert_not_nil assigns(:sources)
    assert_response :success
  end

  test "get matching with ajax" do
    get :matching, controls_id: queries(:query_with_test_data).id, cases_id: queries(:query_with_test_data).id, controls_per_case: 2, criteria_ids: [variables(:choices).id], variable_ids: [], format: 'js'
    assert_not_nil assigns(:controls)
    assert_not_nil assigns(:cases)
    assert_equal 2, assigns(:controls_per_case)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:matches)
    assert_template 'matching'
  end

  test "get matching csv" do
    get :matching, controls_id: queries(:query_with_test_data).id, cases_id: queries(:query_with_test_data).id, controls_per_case: 2, format: 'csv'
    assert_not_nil assigns(:controls)
    assert_not_nil assigns(:cases)
    assert_equal 2, assigns(:controls_per_case)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:matches)
    assert_response :success
  end

  test "get add variable" do
    post :add_variable, controls_id: queries(:query_with_test_data).id, cases_id: queries(:query_with_test_data).id, format: 'js'
    assert_not_nil assigns(:controls)
    assert_not_nil assigns(:cases)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:all_variables)
    assert_template 'add_variable'
  end

  test "get add criteria" do
    post :add_criteria, controls_id: queries(:query_with_test_data).id, cases_id: queries(:query_with_test_data).id, format: 'js'
    assert_not_nil assigns(:controls)
    assert_not_nil assigns(:cases)
    assert_not_nil assigns(:sources)
    assert_not_nil assigns(:variables)
    assert_template 'add_criteria'
  end

end
