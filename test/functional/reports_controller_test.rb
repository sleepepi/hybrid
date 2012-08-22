require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @report = reports(:report)
    @dataset = reports(:dataset)
  end

  test "should get csv" do
    post :get_csv, id: @report.to_param, query_id: queries(:one).to_param
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:graph_values)
    assert_response :success
  end

  test "should not get csv without valid query" do
    post :get_csv, id: @report.to_param, query_id: -1
    assert_nil assigns(:query)
    assert_response :success
  end

  test "should get table" do
    post :get_table, id: reports(:report_with_data).to_param
    assert_not_nil assigns(:report)
    assert_response :success
  end

  test "should not get table without valid report" do
    post :get_table, id: -1
    assert_nil assigns(:report)
    assert_response :success
  end

  test "should not get table with query that returns no results" do
    post :get_table, id: reports(:empty_report).to_param
    assert_not_nil assigns(:report)
    assert_response :success
  end

  test "should get report table" do
    post :report_table, id: @report.to_param, query_id: queries(:one).to_param, format: 'js'
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:query)
    assert_template 'report_table'
  end

  test "should get report table with test data" do
    post :report_table, id: reports(:report_with_data).to_param, query_id: queries(:query_with_test_data).to_param, format: 'js'
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:query)
    assert_template 'report_table'
  end

  test "should popup edit name box" do
    post :edit_name, id: @report.to_param, query_id: queries(:one).to_param, format: 'js'
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:query)
    assert_template 'edit_name'
  end

  test "edit name should return blank without valid report" do
    post :edit_name, id: -1, query_id: queries(:one).to_param, format: 'js'
    assert_response :success
  end

  test "should save name" do
    post :save_name, id: @report.to_param, query_id: queries(:one).to_param, report: { name: 'My New Name' }, format: 'js'
    assert_equal 'My New Name', assigns(:report).name
    assert_not_nil assigns(:report)
    assert_not_nil assigns(:query)
    assert_template 'save_name'
  end

  test "save name should return blank without valid report" do
    post :save_name, id: -1, query_id: queries(:one).to_param, report: { name: 'My New Name' }, format: 'js'
    assert_response :success
  end

  test "should create report dataset" do
    assert_difference('Report.count') do
      post :create, query_id: queries(:one).to_param, report: { name: 'Dataset Name' }, is_dataset: 'true', format: 'js'
    end
    assert_not_nil assigns(:report)
    assert_template 'datasets'
  end

  test "should create report with report table" do
    assert_difference('Report.count') do
      post :create, query_id: queries(:one).to_param, report: { name: 'Report Name' }, is_dataset: 'false', format: 'js'
    end
    assert_not_nil assigns(:report)
    assert_template 'reports'
  end

  test "should create report dataset with template" do
    assert_difference('Report.count') do
      post :create, query_id: queries(:one).to_param, report: { name: 'Dataset Name' }, is_dataset: 'true', template_report_id: @dataset.to_param, format: 'js'
    end
    assert_not_nil assigns(:report)
    assert_template 'datasets'
  end

  test "should create report with report table with template" do
    assert_difference('Report.count') do
      post :create, query_id: queries(:one).to_param, report: { name: 'Report Name' }, is_dataset: 'false', template_report_id: @report.to_param, format: 'js'
    end
    assert_not_nil assigns(:report)
    assert_template 'reports'
  end

  test "should not create report without valid query" do
    assert_difference('Report.count', 0) do
      post :create, query_id: -1, report: { name: 'Dataset Name' }, is_dataset: 'true', format: 'js'
    end
    assert_nil assigns(:query)
    assert_nil assigns(:report)
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @report.to_param, query_id: queries(:one).to_param, format: 'js'
    assert_template 'edit'
  end

  test "should not get edit with invalid query" do
    get :edit, id: @report.to_param, query_id: -1, format: 'js'
    assert_nil assigns(:query)
    assert_nil assigns(:report)
    assert_response :success
  end

  test "should destroy report with report table" do
    assert_difference('Report.count', -1) do
      delete :destroy, id: @report.to_param, query_id: queries(:one).to_param, format: 'js'
    end

    assert_template 'reports'
  end

  test "should destroy report dataset" do
    assert_difference('Report.count', -1) do
      delete :destroy, id: @dataset.to_param, query_id: queries(:one).to_param, format: 'js'
    end

    assert_template 'datasets'
  end

  test "should not destroy report without valid report id" do
    assert_difference('Report.count', 0) do
      delete :destroy, id: -1, query_id: queries(:one).to_param, format: 'js'
    end
    assert_nil assigns(:report)
    assert_response :success
  end

  # Make sure anchors are always first, followed by the rest of the concepts
  test "should reorder report concepts (only rows)" do
    post :reorder, id: @report.to_param, query_id: queries(:one).to_param, rows: "report_concept_#{report_concepts(:one).to_param},report_concept_#{report_concepts(:two).to_param}", columns: "", format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_equal [true]*2+[false]*0, assigns(:report).report_concepts.collect(&:strata)
    assert_template 'report_table'
  end

  test "should reorder report concepts (only columns)" do
    post :reorder, id: @report.to_param, query_id: queries(:one).to_param, rows: "", columns: "report_concept_#{report_concepts(:one).to_param},report_concept_#{report_concepts(:two).to_param}", format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_equal [true]*0+[false]*2, assigns(:report).report_concepts.collect(&:strata)
    assert_template 'report_table'
  end

  test "should reorder report concepts (rows and columns)" do
    post :reorder, id: @report.to_param, query_id: queries(:one).to_param, rows: "report_concept_#{report_concepts(:two).to_param}", columns: "report_concept_#{report_concepts(:one).to_param}", format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:report)
    assert_equal (1..assigns(:report).report_concepts.size).to_a, assigns(:report).report_concepts.collect(&:position)
    assert_equal [true]*1+[false]*1, assigns(:report).report_concepts.collect(&:strata)
    assert_template 'report_table'
  end

  test "should not reorder report concepts with invalid query" do
    post :reorder, id: @report.to_param, query_id: -1, rows: "report_concept_#{report_concepts(:two).to_param}", columns: "report_concept_#{report_concepts(:one).to_param}", format: 'js'
    assert_nil assigns(:query)
    assert_response :success
  end
end
