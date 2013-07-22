require 'test_helper'

class SearchesControllerTest < ActionController::TestCase
  setup do
    login(users(:valid))
    @search = searches(:one)
  end

  test "total records count" do
    post :total_records_count, id: searches(:search_with_sources), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a search with sources" do
    post :total_records_count, id: searches(:search_with_sources), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a search without sources" do
    post :total_records_count, id: searches(:three), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count for a search with negated concepts" do
    post :total_records_count, id: searches(:search_with_negated_concepts), format: 'js'
    assert_not_nil assigns(:sql_conditions)
    assert_not_nil assigns(:overall_errors)
    assert_not_nil assigns(:overall_totals)
    assert_template 'total_records_count'
  end

  test "total records count renders blank if no search is provided" do
    post :total_records_count, id: -1, format: 'js'
    assert_response :success
  end

  test "should reorder search concepts" do
    post :reorder, id: searches(:search_with_sources), order: "criterium_#{criteria(:four).to_param},criterium_#{criteria(:three).to_param}", format: 'js'
    assert_equal [[0,criteria(:four).to_param],[1,criteria(:three).to_param]], assigns(:search).criteria.collect{|qc| [qc.position, qc.id.to_s]}
    assert_template 'criteria'
  end

  test "reorder should return blank without valid search" do
    post :reorder, id: -1, order: "criterium_#{criteria(:four).to_param},criterium_#{criteria(:three).to_param}", format: 'js'
    assert_response :success
  end

  test "should list data files associated with search" do
    post :data_files, id: searches(:search_with_sources), file_type_id: 1, format: 'js'
    assert_template 'data_files'
  end

  test "data files should return blank without valid search" do
    post :data_files, id: -1, file_type_id: 1, format: 'js'
    assert_response :success
  end

  test "should load data file type" do
    post :load_file_type, id: searches(:search_with_sources), file_type_id: 1, format: 'js'
    assert_template 'load_file_type'
  end

  test "load data file type should return blank without valid search" do
    post :load_file_type, id: -1, file_type_id: 1, format: 'js'
    assert_response :success
  end

  test "should popup edit name box" do
    post :edit, id: searches(:search_with_sources), format: 'js'
    assert_template 'edit'
  end

  test "edit name should return blank without valid search" do
    post :edit, id: -1, format: 'js'
    assert_response :success
  end

  test "should save name" do
    post :update, id: searches(:search_with_sources), search: {name: 'My New Name'}, format: 'js'
    assert_equal 'My New Name', assigns(:search).name
    assert_template 'show'
  end

  test "save name should return blank without valid search" do
    post :update, id: -1, search: { name: 'My New Name' }, format: 'js'
    assert_response :success
  end

  test "should undo last change" do
    post :undo, id: searches(:search_with_sources), format: 'js'
    assert_not_nil assigns(:search)
    assert_template 'criteria'
  end

  test "should not undo last change without valid id" do
    post :undo, id: -1, format: 'js'
    assert_response :success
  end

  test "should undo last create action" do
    post :undo, id: searches(:search_with_history), format: 'js'
    assert_not_nil assigns(:search)
    assert_equal 0, assigns(:search).criteria.size
    assert_equal 0, assigns(:search).history_position
    assert_response :success
  end

  test "should undo last update action" do
    post :undo, id: searches(:search_with_history_update_change), format: 'js'
    assert_not_nil assigns(:search)
    assert_nil assigns(:search).criteria.first.value
    assert_equal 0, assigns(:search).history_position
    assert_response :success
  end

  test "should redo last change" do
    post :redo, id: searches(:search_with_sources), format: 'js'
    assert_not_nil assigns(:search)
    assert_template 'criteria'
  end

  test "should redo undone create action" do
    post :redo, id: searches(:search_with_undone_history), format: 'js'
    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 1, assigns(:search).history_position
    assert_response :success
  end

  test "should redo undone update action" do
    post :redo, id: searches(:search_with_undone_history_update_change), format: 'js'
    assert_not_nil assigns(:search)
    assert_equal '20', assigns(:search).criteria.first.value
    assert_equal 1, assigns(:search).history_position
    assert_response :success
  end

  test "should not redo last change without valid id" do
    post :redo, id: -1, format: 'js'
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:searches)
  end

  test "should get new" do
    get :new
    assert_redirected_to root_path
  end

  test "should show search" do
    get :show, id: @search
    assert_response :success
  end

  test "should copy search" do
    post :copy, id: @search
    assert_not_nil assigns(:search)
    assert_equal @search.criteria.size, assigns(:search).criteria.size
    assert_equal @search.query_sources.size, assigns(:search).query_sources.size
    assert_equal @search.name + " Copy", assigns(:search).name
    assert_redirected_to root_path
  end

  test "should not copy search with invalid id" do
    post :copy, id: -1
    assert_nil assigns(:search)
    assert_equal "You do not have access to that search", flash[:alert]
    assert_redirected_to root_path
  end

  # test "should get edit" do
  #   get :edit, id: @search
  #   assert_response :success
  # end
  #
  # test "should update search" do
  #   put :update, id: @search, search: @search.attributes
  #   assert_redirected_to search_path(assigns(:search))
  # end

  test "should destroy search" do
    assert_difference('Search.current.count', -1) do
      delete :destroy, id: @search
    end

    assert_redirected_to searches_path
  end
end
