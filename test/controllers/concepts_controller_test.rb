require 'test_helper'

class ConceptsControllerTest < ActionController::TestCase
  setup do
    login(users(:valid))
    @concept = concepts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:concepts)
  end

  test "should get autocomplete" do
    get :index, autocomplete: 'true', format: 'js'
    assert_not_nil assigns(:concepts)
  end

  test "should get info for categorical concept" do
    post :info, id: concepts(:categorical).to_param, query_id: queries(:three).to_param, format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)
    assert_not_nil assigns(:mapping)

    assert_template 'info'
  end

  test "should get info for continuous concept" do
    post :info, id: concepts(:continuous).to_param, query_id: queries(:one).to_param, format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)
    assert_not_nil assigns(:mapping)

    assert_template 'info'
  end

  test "should get info for continuous concept with formula" do
    post :info, id: concepts(:formula).to_param, query_id: queries(:one).to_param, format: 'js'

    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)
    assert_not_nil assigns(:mapping)

    assert_template 'info'
  end

  test "should get info and render blank without concept" do
    post :info, id: -1, query_id: queries(:three).to_param, format: 'js'
    assert_nil assigns(:concept)
    assert_response :success
  end

  test "search folder" do
    post :search_folder, id: concepts(:categorical).to_param, query_id: queries(:three).to_param, format: 'js'
    assert_not_nil assigns(:query)
    assert_template 'search_folder'
  end

  test "open folder" do
    post :open_folder, id: concepts(:categorical).to_param, query_id: queries(:three).to_param, format: 'js'
    assert_not_nil assigns(:query)
    assert_template 'open_folder'
  end

  test "search folder opens popup" do
    post :search_folder, id: concepts(:categorical).to_param, query_id: queries(:three).to_param, popup: 'true', format: 'js'
    assert_not_nil assigns(:query)
    assert_template 'popup'
  end

  # TODO: Test Concept Creation, Deletion, etc
  # test "should get new" do
  #   get :new
  #   assert_response :success
  # end
  #
  # test "should create concept" do
  #   assert_difference('Concept.count') do
  #     post :create, concept: @concept.attributes
  #   end
  #
  #   assert_redirected_to concept_path(assigns(:concept))
  # end

  test "should show concept" do
    get :show, id: concepts(:boolean).to_param
    assert_response :success
  end

  test "should redirect if concept is not found" do
    get :show, id: -1
    assert_redirected_to concepts_path
  end

  # test "should get edit" do
  #   get :edit, id: @concept.to_param
  #   assert_response :success
  # end
  #
  # test "should update concept" do
  #   put :update, id: @concept.to_param, concept: @concept.attributes
  #   assert_redirected_to concept_path(assigns(:concept))
  # end
  #
  # test "should destroy concept" do
  #   assert_difference('Concept.count', -1) do
  #     delete :destroy, id: @concept.to_param
  #   end
  #
  #   assert_redirected_to concepts_path
  # end
end
