require 'test_helper'

class SourcesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source = sources(:two)
  end

  test "should download file" do
    # TODO figure out how to download files that exist...
    get :download_file, id: @source, file_locator: 'test', file_type: '.txt'
    assert_not_nil assigns(:source)
    assert_response :success
  end

  test "should not download file that does not exist" do
    get :download_file, id: @source, file_locator: 'sample', file_type: '.txt'
    assert_not_nil assigns(:source)
    assert_response :success
  end

  test "should not download file with invalid source" do
    get :download_file, id: -1, file_locator: 'sample', file_type: '.txt'
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should auto map" do
    post :auto_map, id: @source, table: '', dictionary_id: dictionaries(:one).to_param, namespace: '', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:columns)
    assert_not_nil assigns(:max_pages)
    assert_not_nil assigns(:error)
    assert_template 'table_columns'
  end

  test "should auto map single table" do
    post :auto_map, id: @source, table: 'table', dictionary_id: dictionaries(:one).to_param, namespace: '', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:columns)
    assert_not_nil assigns(:max_pages)
    assert_not_nil assigns(:error)
    assert_template 'table_columns'
  end

  test "should not auto map with invalid source" do
    post :auto_map, id: -1, table: '', dictionary_id: dictionaries(:one).to_param, namespace: '', format: 'js'
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should remove all mappings" do
    post :remove_all_mappings, id: @source, format: 'js'
    assert_equal 0, assigns(:source).mappings.size
    assert_redirected_to assigns(:source)
  end

  test "should not remove all mappings without appropriate privileges" do
    post :remove_all_mappings, id: sources(:one), format: 'js'
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should not remove all mappings with invalid source" do
    post :remove_all_mappings, id: -1, format: 'js'
    assert_nil assigns(:source)
    assert_response :success
  end

  test "should show table columns" do
    post :table_columns, id: @source, format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:columns)
    assert_not_nil assigns(:max_pages)
    assert_not_nil assigns(:error)
    assert_template 'table_columns'
  end

  test "should show filtered table columns" do
    post :table_columns, id: @source, filter_unmapped: '1', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:columns)
    assert_not_nil assigns(:max_pages)
    assert_not_nil assigns(:error)
    assert_template 'table_columns'
  end

  test "should not show table columns for invalid source" do
    post :table_columns, id: -1, format: 'js'
    assert_nil assigns(:source)
    assert_template 'mapping_privilege'
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sources)
  end

  test "should get index for autocomplete" do
    get :index, autocomplete: 'true', format: 'js'
    assert_not_nil assigns(:sources)
    # assert_template 'autocomplete'
  end

  test "should get index for popup" do
    get :index, popup: 'true', query_id: queries(:one).to_param, format: 'js'
    assert_not_nil assigns(:sources)
    assert_template 'popup'
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create source" do
    assert_difference('Source.count') do
      post :create, source: { name: 'Source Four', wrapper: 'mysql', visible: true, repository: 'ftp' }
    end

    assert_redirected_to source_path(assigns(:source))
  end

  test "should not create source with blank name" do
    assert_difference('Source.count', 0) do
      post :create, source: { name: '', wrapper: 'mysql', visible: true, repository: 'ftp' }
    end
    assert_not_nil assigns(:source)
    assert assigns(:source).errors.size > 0
    assert_template 'new'
  end

  test "should show source" do
    get :show, id: @source, query_id: queries(:one).to_param
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:query)
    assert_template 'show'
  end

  test "should show source info popup" do
    get :show, id: @source, query_id: queries(:one).to_param, popup: 'true', format: 'js'
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:query)
    assert_template 'info'
  end

  test "should not show source info popup with invalid query" do
    get :show, id: @source, query_id: -1, popup: 'true', format: 'js'
    assert_not_nil assigns(:source)
    assert_nil assigns(:query)
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @source
    assert_response :success
  end

  test "should update source" do
    put :update, id: @source, source: @source.attributes
    assert_redirected_to source_path(assigns(:source))
  end

  test "should not update source with blank name" do
    put :update, id: @source, source: { name: '' }
    assert_not_nil assigns(:source)
    assert_template 'edit'
  end

  test "should not update source without valid id" do
    put :update, id: -1, source: @source.attributes
    assert_nil assigns(:source)
    assert_redirected_to sources_path
  end

  test "should destroy source" do
    assert_difference('Source.current.count', -1) do
      delete :destroy, id: @source
    end

    assert_redirected_to sources_path
  end

  test "should not destroy invalid source" do
    assert_difference('Source.current.count', 0) do
      delete :destroy, id: -1
    end

    assert_redirected_to sources_path
  end
end
