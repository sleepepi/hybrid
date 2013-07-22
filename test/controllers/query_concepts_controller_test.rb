require 'test_helper'

class QueryConceptsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @search = searches(:one)
    @query_concept = query_concepts(:one)
  end

  test "should mark all query concepts as selected" do
    post :select_all, search_id: @search, selected: 'true', format: 'js'

    assert_equal assigns(:search).query_concepts.size, assigns(:search).query_concepts.where(selected: true).size
    assert_template 'query_concepts'
  end

  test "should not mark query concepts as selected for invalid query" do
    post :select_all, search_id: -1, selected: 'true', format: 'js'
    assert_nil assigns(:search)
    assert_response :success
  end

  test "should clear selection of all query concepts" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'

    assert_equal assigns(:search).query_concepts.size, assigns(:search).query_concepts.where(selected: false).size
    assert_template 'query_concepts'
  end

  test "should mark individual query concept as selected" do
    post :mark_selected, search_id: @search, query_concept_id: query_concepts(:one).to_param, selected: 'true', format: 'js'
    assert assigns(:search)
    assert assigns(:query_concept)
    assert_equal true, assigns(:query_concept).selected
    assert_response :success
  end

  test "should clear selection for individual query concept" do
    post :mark_selected, search_id: @search, query_concept_id: query_concepts(:categorical), selected: 'false', format: 'js'
    assert assigns(:search)
    assert assigns(:query_concept)
    assert_equal false, assigns(:query_concept).selected
    assert_response :success
  end

  test "should copy selected query concepts and append to end of query" do
    assert_difference('searches(:one).query_concepts.size', searches(:one).query_concepts.where(selected: true).size) do
      post :copy_selected, search_id: @search, format: 'js'
    end

    assert_template 'query_concepts'
  end

  test "should copy no query concepts if none are selected" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('searches(:one).query_concepts.size', 0) do
      post :copy_selected, search_id: @search, format: 'js'
    end

    assert_response :success
  end

  test "should trash selected query concepts" do
    assert_difference('searches(:one).query_concepts.size', -1*searches(:one).query_concepts.where(selected: true).size) do
      post :trash_selected, search_id: @search, format: 'js'
    end

    assert_equal 0, assigns(:search).query_concepts.where(selected: true).size
    assert_template 'query_concepts'
  end

  test "should leave query untouched if no query concepts are selected" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('searches(:one).query_concepts.count', 0) do
      post :trash_selected, search_id: @search, format: 'js'
    end

    assert_response :success
  end

  test "should indent selected query concepts" do
    indent = 1
    assert_difference('searches(:one).query_concepts.where(selected: true).collect(&:level).sum', indent * searches(:one).query_concepts.where(selected: true).size ) do
      post :indent, search_id: @search, indent: indent, format: 'js'
    end

    assert assigns(:search)
    assert_template 'query_concepts'
  end

  test "should not indent selected query concepts with invalid query" do
    post :indent, search_id: -1, indent: 1, format: 'js'

    assert_nil assigns(:search)
    assert_response :success
  end

  test "should update the right operator for a query concept" do
    right_operator = 'or'
    post :right_operator, search_id: @search, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert assigns(:search)
    assert assigns(:query_concept)
    assert right_operator, assigns(:query_concept).right_operator
    assert_template 'query_concepts'
  end

  test "should not update the right operator if an invalid right operator is given for a query concept" do
    right_operator = 'nand'
    post :right_operator, search_id: @search, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert assigns(:search)
    assert assigns(:query_concept)
    assert_not_equal right_operator, assigns(:query_concept).right_operator
    assert_template 'query_concepts'
  end

  test "should not update the right operator for a query concept with invalid query" do
    right_operator = 'or'
    post :right_operator, search_id: -1, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert_nil assigns(:search)
    assert_response :success
  end

  test "should create query concept" do
    assert_difference('QueryConcept.count') do
      post :create, search_id: @search, query_concept: @query_concept.attributes, variable_id: variables(:numeric), format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'query_concepts'
  end

  test "should not create query concept without valid concept" do
    assert_difference('QueryConcept.count', 0) do
      post :create, search_id: @search, query_concept: @query_concept.attributes, variable_id: '-1', format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_response :success
  end

  test "should get edit for a continuous query concept" do
    get :edit, search_id: @search, id: @query_concept, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'edit'
  end

  test "should get edit for a categorical query concept" do
    get :edit, search_id: @search, id: query_concepts(:categorical), format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'edit'
  end

  test "should update query concept" do
    put :update, search_id: @search, id: @query_concept, query_concept: @query_concept.attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for categorical concept" do
    put :update, search_id: @search, id: query_concepts(:categorical), query_concept: query_concepts(:categorical).attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for categorical concept with value ids" do
    put :update, search_id: @search, id: query_concepts(:categorical), query_concept: query_concepts(:categorical).attributes, values: [ '11', '14' ], format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for date concept" do
    put :update, search_id: @search, id: query_concepts(:date), query_concept: query_concepts(:date).attributes, start_date: '01/01/2011', format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should not update query concept with invalid id" do
    put :update, search_id: @search, id: -1, query_concept: @query_concept.attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_nil assigns(:query_concept)
    assert_response :success
  end

  test "should destroy query concept" do
    assert_difference('QueryConcept.current.count', -1) do
      delete :destroy, search_id: @search, id: @query_concept, format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'query_concepts'
  end

  test "should not destroy query concept with invalid id" do
    assert_difference('QueryConcept.count', 0) do
      delete :destroy, search_id: @search, id: -1, format: 'js'
    end
    assert_not_nil assigns(:search)
    assert_nil assigns(:query_concept)
    assert_response :success
  end
end
