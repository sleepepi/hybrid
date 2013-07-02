require 'test_helper'

class ReportConceptsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @query = queries(:one)
    @report = reports(:report)
    @report_concept = report_concepts(:one)
  end

  test "should create report concept" do
    assert_difference('ReportConcept.count') do
      post :create, query_id: @query, report_id: @report, variable_id: variables(:numeric), format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_concepts'
  end

  test "should not create report concept without valid report and query" do
    assert_difference('ReportConcept.count', 0) do
      post :create, query_id: -1, report_id: -1, variable_id: variables(:numeric), format: 'js'
    end

    assert_nil assigns(:query)
    assert_nil assigns(:report)
    assert_response :success
  end

  test "should update report concept" do
    put :update, query_id: @query, report_id: @report, id: @report_concept, report_concept: { statistic: '' }, format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:report_concept)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_table'
  end

  test "should not update report concept with invalid id" do
    put :update, query_id: @query, report_id: @report, id: -1, report_concept: { statistic: '' }, format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_nil assigns(:report_concept)
    assert_response :success
  end

  test "should destroy report concept" do
    assert_difference('ReportConcept.count', -1) do
      delete :destroy, query_id: @query, report_id: @report, id: @report_concept.to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_concepts'
  end

  test "should not destroy report concept with invalid id" do
    assert_difference('ReportConcept.count', 0) do
      delete :destroy, query_id: @query, report_id: @report, id: -1, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_nil assigns(:report_concept)
    assert_response :success
  end
end
