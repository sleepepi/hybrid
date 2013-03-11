require 'test_helper'

class ReportConceptsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @report_concept = report_concepts(:one)
  end

  test "should create report concept" do
    assert_difference('ReportConcept.count') do
      post :create, query_id: queries(:one).to_param, report_id: reports(:report).to_param, concept_id: concepts(:continuous).to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_concepts'
  end

  test "should create report concept for external concept" do
    assert_difference('ReportConcept.count') do
      post :create, query_id: queries(:one).to_param, report_id: reports(:report).to_param, concept_id: "#{sources(:i2b2_valid).to_param},external_concept_key", format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_concepts'
  end

  test "should not create report concept without valid report and query" do
    assert_difference('ReportConcept.count', 0) do
      post :create, query_id: -1, report_id: -1, concept_id: concepts(:continuous).to_param, format: 'js'
    end

    assert_nil assigns(:query)
    assert_nil assigns(:report)
    assert_response :success
  end

  test "should update report concept" do
    put :update, id: @report_concept.to_param, query_id: queries(:one).to_param, report_concept: { statistic: '' }, format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:report_concept)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_table'
  end

  test "should not update report concept with invalid id" do
    put :update, id: -1, query_id: queries(:one).to_param, report_concept: { statistic: '' }, format: 'js'
    assert_nil assigns(:report)
    assert_nil assigns(:report_concept)
    assert_response :success
  end

  test "should destroy report concept" do
    assert_difference('ReportConcept.count', -1) do
      delete :destroy, id: @report_concept.to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_template 'report_concepts'
  end

  test "should not destroy report concept with invalid id" do
    assert_difference('ReportConcept.count', 0) do
      delete :destroy, id: -1, format: 'js'
    end

    assert_nil assigns(:query)
    assert_nil assigns(:report)
    assert_nil assigns(:report_concept)
    assert_response :success
  end
end
