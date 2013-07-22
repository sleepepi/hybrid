require 'test_helper'

class CriteriaControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @search = searches(:one)
    @criterium = criteria(:one)
  end

  test "should mark all criteria as selected" do
    post :select_all, search_id: @search, selected: 'true', format: 'js'

    assert_equal assigns(:search).criteria.size, assigns(:search).criteria.where(selected: true).size
    assert_template 'criteria'
  end

  test "should not mark criteria as selected for invalid query" do
    post :select_all, search_id: -1, selected: 'true', format: 'js'
    assert_nil assigns(:search)
    assert_response :success
  end

  test "should clear selection of all criteria" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'

    assert_equal assigns(:search).criteria.size, assigns(:search).criteria.where(selected: false).size
    assert_template 'criteria'
  end

  test "should mark individual criterium as selected" do
    post :mark_selected, search_id: @search, criterium_id: criteria(:one).to_param, selected: 'true', format: 'js'
    assert assigns(:search)
    assert assigns(:criterium)
    assert_equal true, assigns(:criterium).selected
    assert_response :success
  end

  test "should clear selection for individual criterium" do
    post :mark_selected, search_id: @search, criterium_id: criteria(:categorical), selected: 'false', format: 'js'
    assert assigns(:search)
    assert assigns(:criterium)
    assert_equal false, assigns(:criterium).selected
    assert_response :success
  end

  test "should copy selected criteria and append to end of query" do
    assert_difference('searches(:one).criteria.size', searches(:one).criteria.where(selected: true).size) do
      post :copy_selected, search_id: @search, format: 'js'
    end

    assert_template 'criteria'
  end

  test "should copy no criteria if none are selected" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('searches(:one).criteria.size', 0) do
      post :copy_selected, search_id: @search, format: 'js'
    end

    assert_response :success
  end

  test "should trash selected criteria" do
    assert_difference('searches(:one).criteria.size', -1*searches(:one).criteria.where(selected: true).size) do
      post :trash_selected, search_id: @search, format: 'js'
    end

    assert_equal 0, assigns(:search).criteria.where(selected: true).size
    assert_template 'criteria'
  end

  test "should leave query untouched if no criteria are selected" do
    post :select_all, search_id: @search, selected: 'false', format: 'js'
    assert_response :success

    assert_difference('searches(:one).criteria.count', 0) do
      post :trash_selected, search_id: @search, format: 'js'
    end

    assert_response :success
  end

  test "should indent selected criteria" do
    indent = 1
    assert_difference('searches(:one).criteria.where(selected: true).collect(&:level).sum', indent * searches(:one).criteria.where(selected: true).size ) do
      post :indent, search_id: @search, indent: indent, format: 'js'
    end

    assert assigns(:search)
    assert_template 'criteria'
  end

  test "should not indent selected criteria with invalid query" do
    post :indent, search_id: -1, indent: 1, format: 'js'

    assert_nil assigns(:search)
    assert_response :success
  end

  test "should update the right operator for a criterium" do
    right_operator = 'or'
    post :right_operator, search_id: @search, criterium_id: criteria(:one), right_operator: right_operator, format: 'js'
    assert assigns(:search)
    assert assigns(:criterium)
    assert right_operator, assigns(:criterium).right_operator
    assert_template 'criteria'
  end

  test "should not update the right operator if an invalid right operator is given for a criterium" do
    right_operator = 'nand'
    post :right_operator, search_id: @search, criterium_id: criteria(:one), right_operator: right_operator, format: 'js'
    assert assigns(:search)
    assert assigns(:criterium)
    assert_not_equal right_operator, assigns(:criterium).right_operator
    assert_template 'criteria'
  end

  test "should not update the right operator for a criterium with invalid query" do
    right_operator = 'or'
    post :right_operator, search_id: -1, criterium_id: criteria(:one), right_operator: right_operator, format: 'js'
    assert_nil assigns(:search)
    assert_response :success
  end

  test "should create criterium" do
    assert_difference('Criterium.count') do
      post :create, search_id: @search, criterium: @criterium.attributes, variable_id: variables(:numeric), format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'criteria'
  end

  test "should not create criterium without valid concept" do
    assert_difference('Criterium.count', 0) do
      post :create, search_id: @search, criterium: @criterium.attributes, variable_id: '-1', format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_response :success
  end

  test "should get edit for a continuous criterium" do
    get :edit, search_id: @search, id: @criterium, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'edit'
  end

  test "should get edit for a categorical criterium" do
    get :edit, search_id: @search, id: criteria(:categorical), format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'edit'
  end

  test "should update criterium" do
    put :update, search_id: @search, id: @criterium, criterium: @criterium.attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'criteria'
  end

  test "should update criterium for categorical concept" do
    put :update, search_id: @search, id: criteria(:categorical), criterium: criteria(:categorical).attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'criteria'
  end

  test "should update criterium for categorical concept with value ids" do
    put :update, search_id: @search, id: criteria(:categorical), criterium: criteria(:categorical).attributes, values: [ '11', '14' ], format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'criteria'
  end

  test "should update criterium for date concept" do
    put :update, search_id: @search, id: criteria(:date), criterium: criteria(:date).attributes, start_date: '01/01/2011', format: 'js'
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:criterium)
    assert_template 'criteria'
  end

  test "should not update criterium with invalid id" do
    put :update, search_id: @search, id: -1, criterium: @criterium.attributes, format: 'js'
    assert_not_nil assigns(:search)
    assert_nil assigns(:criterium)
    assert_response :success
  end

  test "should destroy criterium" do
    assert_difference('Criterium.current.count', -1) do
      delete :destroy, search_id: @search, id: @criterium, format: 'js'
    end

    assert_not_nil assigns(:search)
    assert_template 'criteria'
  end

  test "should not destroy criterium with invalid id" do
    assert_difference('Criterium.count', 0) do
      delete :destroy, search_id: @search, id: -1, format: 'js'
    end
    assert_not_nil assigns(:search)
    assert_nil assigns(:criterium)
    assert_response :success
  end
end
