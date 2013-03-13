require 'test_helper'

class QueriesControllerTest < ActionController::TestCase
  setup do
    login(users(:valid))
    @query = queries(:one)
  end

  test "total records count" do
    post :total_records_count, id: queries(:query_with_sources), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a query with sources" do
    post :total_records_count, id: queries(:query_with_sources), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a query without sources" do
    post :total_records_count, id: queries(:three), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a query with negated concepts" do
    post :total_records_count, id: queries(:query_with_negated_concepts), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count renders blank if no query is provided" do
    post :total_records_count, id: -1
    assert_response :success
  end

  test "should reorder query concepts" do
    post :reorder, id: queries(:query_with_sources), order: "query_concept_#{query_concepts(:four).to_param},query_concept_#{query_concepts(:three).to_param}", format: 'js'
    assert_equal [[0,query_concepts(:four).to_param],[1,query_concepts(:three).to_param]], assigns(:query).query_concepts.collect{|qc| [qc.position, qc.id.to_s]}
    assert_template 'query_concepts'
  end

  test "reorder should return blank without valid query" do
    post :reorder, id: -1, order: "query_concept_#{query_concepts(:four).to_param},query_concept_#{query_concepts(:three).to_param}", format: 'js'
    assert_response :success
  end

  test "should list data files associated with query" do
    post :data_files, id: queries(:query_with_sources), file_type_id: 1, format: 'js'
    assert_template 'data_files'
  end

  test "data files should return blank without valid query" do
    post :data_files, id: -1, file_type_id: 1, format: 'js'
    assert_response :success
  end

  test "should load data file type" do
    post :load_file_type, id: queries(:query_with_sources), file_type_id: 1, format: 'js'
    assert_template 'load_file_type'
  end

  test "load data file type should return blank without valid query" do
    post :load_file_type, id: -1, file_type_id: 1, format: 'js'
    assert_response :success
  end

  test "should popup edit name box" do
    post :edit_name, id: queries(:query_with_sources), format: 'js'
    assert_template 'edit_name'
  end

  test "edit name should return blank without valid query" do
    post :edit_name, id: -1, format: 'js'
    assert_response :success
  end

  test "should save name" do
    post :save_name, id: queries(:query_with_sources), query: {name: 'My New Name'}, format: 'js'
    assert_equal 'My New Name', assigns(:query).name
    assert_template 'save_name'
  end

  test "save name should return blank without valid query" do
    post :save_name, id: -1, query: {name: 'My New Name'}, format: 'js'
    assert_response :success
  end

  test "should undo last change" do
    post :undo, id: queries(:query_with_sources), format: 'js'
    assert_not_nil assigns(:query)
    assert_template 'query_concepts'
  end

  test "should not undo last change without valid id" do
    post :undo, id: -1, format: 'js'
    assert_response :success
  end

  test "should undo last create action" do
    post :undo, id: queries(:query_with_history), format: 'js'
    assert_not_nil assigns(:query)
    assert_equal 0, assigns(:query).query_concepts.size
    assert_equal 0, assigns(:query).history_position
    assert_response :success
  end

  test "should undo last update action" do
    post :undo, id: queries(:query_with_history_update_change), format: 'js'
    assert_not_nil assigns(:query)
    assert_nil assigns(:query).query_concepts.first.value
    assert_equal 0, assigns(:query).history_position
    assert_response :success
  end

  test "should redo last change" do
    post :redo, id: queries(:query_with_sources), format: 'js'
    assert_not_nil assigns(:query)
    assert_template 'query_concepts'
  end

  test "should redo undone create action" do
    post :redo, id: queries(:query_with_undone_history), format: 'js'
    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 1, assigns(:query).history_position
    assert_response :success
  end

  test "should redo undone update action" do
    post :redo, id: queries(:query_with_undone_history_update_change), format: 'js'
    assert_not_nil assigns(:query)
    assert_equal '20', assigns(:query).query_concepts.first.value
    assert_equal 1, assigns(:query).history_position
    assert_response :success
  end

  test "should not redo last change without valid id" do
    post :redo, id: -1, format: 'js'
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:queries)
  end

  test "should get new" do
    get :new
    assert_redirected_to root_path
  end

  # TODO: Refactor QueriesController to use RESTful actions
  # test "should create query" do
  #   assert_difference('Query.count') do
  #     post :create, query: @query.attributes
  #   end
  #
  #   assert_redirected_to query_path(assigns(:query))
  # end

  test "should show query" do
    get :show, id: @query
    assert_response :success
  end

  test "should copy query" do
    post :copy, id: @query
    assert_not_nil assigns(:query)
    assert_equal @query.query_concepts.size, assigns(:query).query_concepts.size
    assert_equal @query.query_sources.size, assigns(:query).query_sources.size
    assert_equal @query.name + " Copy", assigns(:query).name
    assert_redirected_to root_path
  end

  test "should not copy query with invalid id" do
    post :copy, id: -1
    assert_nil assigns(:query)
    assert_equal "You do not have access to that query", flash[:alert]
    assert_redirected_to root_path
  end

  # test "should get edit" do
  #   get :edit, id: @query
  #   assert_response :success
  # end
  #
  # test "should update query" do
  #   put :update, id: @query, query: @query.attributes
  #   assert_redirected_to query_path(assigns(:query))
  # end

  test "should destroy query" do
    assert_difference('Query.current.count', -1) do
      delete :destroy, id: @query
    end

    assert_redirected_to queries_path
  end
end
