require 'test_helper'

class QueryConceptsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @query_concept = query_concepts(:one)
  end

  test "should mark all query concepts as selected" do
    post :select_all, query_id: queries(:one).to_param, selected: 'true', format: 'js'

    assert_equal assigns(:query).query_concepts.size, assigns(:query).query_concepts.where(selected: true).size
    assert_template 'query_concepts'
  end

  test "should not mark query concepts as selected for invalid query" do
    post :select_all, query_id: -1, selected: 'true', format: 'js'
    assert_nil assigns(:query)
    assert_response :success
  end

  test "should clear selection of all query concepts" do
    post :select_all, query_id: queries(:one).to_param, selected: 'false', format: 'js'

    assert_equal assigns(:query).query_concepts.size, assigns(:query).query_concepts.where(selected: false).size
    assert_template 'query_concepts'
  end

  test "should mark individual query concept as selected" do
    post :mark_selected, query_id: queries(:one).to_param, query_concept_id: query_concepts(:one).to_param, selected: 'true', format: 'js'
    assert assigns(:query)
    assert assigns(:query_concept)
    assert_equal true, assigns(:query_concept).selected
    assert_response :success
  end

  test "should clear selection for individual query concept" do
    post :mark_selected, query_id: queries(:one).to_param, query_concept_id: query_concepts(:categorical), selected: 'false', format: 'js'
    assert assigns(:query)
    assert assigns(:query_concept)
    assert_equal false, assigns(:query_concept).selected
    assert_response :success
  end

  test "should copy selected query concepts and append to end of query" do
    assert_difference('queries(:one).query_concepts.size', queries(:one).query_concepts.where(selected: true).size) do
      post :copy_selected, query_id: queries(:one).to_param, format: 'js'
    end

    assert_template 'query_concepts'
  end

  test "should copy no query concepts if none are selected" do
    post :select_all, query_id: queries(:one).to_param, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('queries(:one).query_concepts.size', 0) do
      post :copy_selected, query_id: queries(:one).to_param, format: 'js'
    end

    assert_response :success
  end

  test "should trash selected query concepts" do
    assert_difference('queries(:one).query_concepts.size', -1*queries(:one).query_concepts.where(selected: true).size) do
      post :trash_selected, query_id: queries(:one).to_param, format: 'js'
    end

    assert_equal 0, assigns(:query).query_concepts.where(selected: true).size
    assert_template 'query_concepts'
  end

  test "should leave query untouched if no query concepts are selected" do
    post :select_all, query_id: queries(:one).to_param, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('queries(:one).query_concepts.count', 0) do
      post :trash_selected, query_id: queries(:one).to_param, format: 'js'
    end

    assert_response :success
  end

  test "should indent selected query concepts" do
    indent = 1
    assert_difference('queries(:one).query_concepts.where(selected: true).collect(&:level).sum', indent * queries(:one).query_concepts.where(selected: true).size ) do
      post :indent, query_id: queries(:one).to_param, indent: indent, format: 'js'
    end

    assert assigns(:query)
    assert_template 'query_concepts'
  end

  test "should not indent selected query concepts with invalid query" do
    post :indent, query_id: -1, indent: 1, format: 'js'

    assert_nil assigns(:query)
    assert_response :success
  end

  test "should update the right operator for a query concept" do
    right_operator = 'or'
    post :right_operator, query_id: queries(:one).to_param, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert assigns(:query)
    assert assigns(:query_concept)
    assert right_operator, assigns(:query_concept).right_operator
    assert_template 'query_concepts'
  end

  test "should not update the right operator if an invalid right operator is given for a query concept" do
    right_operator = 'nand'
    post :right_operator, query_id: queries(:one).to_param, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert assigns(:query)
    assert assigns(:query_concept)
    assert_not_equal right_operator, assigns(:query_concept).right_operator
    assert_template 'query_concepts'
  end

  test "should not update the right operator for a query concept with invalid query" do
    right_operator = 'or'
    post :right_operator, query_id: -1, query_concept_id: query_concepts(:one), right_operator: right_operator, format: 'js'
    assert_nil assigns(:query)
    assert_response :success
  end

  test "should create query concept" do
    assert_difference('QueryConcept.count') do
      post :create, query_concept: @query_concept.attributes, query_id: queries(:one).to_param, selected_concept_id: concepts(:continuous_with_label).to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_concepts'
  end

  test "should create query concept for external concept" do
    assert_difference('QueryConcept.count') do
      post :create, query_concept: @query_concept.attributes, external_key: 'external_key', source_id: sources(:three).to_param, query_id: queries(:one).to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_concepts'
  end

  test "should not create query concept without valid concept" do
    assert_difference('QueryConcept.count', 0) do
      post :create, query_concept: @query_concept.attributes, query_id: queries(:one).to_param, selected_concept_id: '-1', format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_response :success
  end

  test "should get edit for a continuous query concept" do
    get :edit, id: @query_concept.to_param, format: 'js'
    assert_not_nil assigns(:query_concept)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)
    assert_template 'edit'
  end

  test "should get edit for a categorical query concept" do
    get :edit, id: query_concepts(:categorical).to_param, format: 'js'
    assert_not_nil assigns(:query_concept)
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:concept)
    assert_not_nil assigns(:values)
    assert_not_nil assigns(:categories)
    assert_not_nil assigns(:chart_type)
    assert_not_nil assigns(:chart_element_id)
    assert_not_nil assigns(:stats)
    assert_not_nil assigns(:defaults)
    assert_template 'edit'
  end

  test "should update query concept" do
    put :update, id: @query_concept.to_param, query_concept: @query_concept.attributes, format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for categorical concept" do
    put :update, id: query_concepts(:categorical).to_param, query_concept: query_concepts(:categorical).attributes, format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for categorical concept with value ids" do
    put :update, id: query_concepts(:categorical).to_param, query_concept: query_concepts(:categorical).attributes, value_ids: { '11' => '1', '14' => '1' }, format: 'js' # TODO: Replace hardcoded values
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should update query concept for date concept" do
    put :update, id: query_concepts(:date_concept).to_param, query_concept: query_concepts(:date_concept).attributes, start_date: '01/01/2011', format: 'js'
    assert_not_nil assigns(:query)
    assert_not_nil assigns(:query_concept)
    assert_template 'query_concepts'
  end

  test "should not update query concept with invalid id" do
    put :update, id: -1, query_concept: @query_concept.attributes, format: 'js'
    assert_nil assigns(:query)
    assert_nil assigns(:query_concept)
    assert_response :success
  end

  test "should destroy query concept" do
    assert_difference('QueryConcept.current.count', -1) do
      delete :destroy, id: @query_concept.to_param, format: 'js'
    end

    assert_not_nil assigns(:query)
    assert_template 'query_concepts'
  end

  test "should not destroy query concept with invalid id" do
    assert_difference('QueryConcept.count', 0) do
      delete :destroy, id: -1, format: 'js'
    end
    assert_nil assigns(:query_concept)
    assert_nil assigns(:query)
    assert_response :success
  end
end
