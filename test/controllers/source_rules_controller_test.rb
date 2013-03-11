require 'test_helper'

class SourceRulesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source_rule = source_rules(:one)
  end

  test "should get index" do
    get :index, source_id: sources(:two).to_param
    assert_not_nil assigns(:source_rules)
    assert_response :success
  end

  test "should not get index for invalid source" do
    get :index, source_id: -1
    assert_nil assigns(:source_rules)
    assert_nil assigns(:source)
    assert_redirected_to root_path
  end

  test "should get new" do
    get :new, source_id: sources(:two).to_param
    assert_response :success
  end

  test "should create source rule" do
    assert_difference('SourceRule.count') do
      post :create, source_rule: @source_rule.attributes, source_id: sources(:two).to_param
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:source_rule)
    assert_redirected_to source_rule_path(assigns(:source_rule))
  end

  test "should create source rule with user tokens" do
    assert_difference('SourceRule.count') do
      post :create, source_rule: {actions: ['edit data source rules', 'get count'], user_tokens: "#{users(:admin).to_param},#{users(:pending).to_param}", blocked: false}, source_id: sources(:two).to_param
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:source_rule)
    assert_equal [users(:admin).to_param.to_s, users(:pending).to_param.to_s], assigns(:source_rule).users
    assert_redirected_to source_rule_path(assigns(:source_rule))
  end

  test "should create source rule with all blank attributes" do
    assert_difference('SourceRule.count') do
      post :create, source_id: sources(:two).to_param
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:source_rule)
    assert_equal [], assigns(:source_rule).actions
    assert_equal [], assigns(:source_rule).users
    assert_equal false, assigns(:source_rule).blocked
    assert_redirected_to source_rule_path(assigns(:source_rule))
  end

  test "should not create source rule for invalid source" do
    assert_difference('SourceRule.count', 0) do
      post :create, source_rule: @source_rule.attributes, source_id: -1
    end
    assert_nil assigns(:source)
    assert_nil assigns(:source_rule)
    assert_equal "You do not have access to this source.", flash[:alert]
    assert_redirected_to root_path
  end

  test "should show source rule" do
    get :show, id: @source_rule.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @source_rule.to_param
    assert_response :success
  end

  test "should update source rule" do
    put :update, id: @source_rule.to_param, source_rule: {user_tokens: '', description: '', name: '', blocked: true, rules: {'get_count' => '1'}}, source_id: sources(:two).to_param
    assert_redirected_to source_rule_path(assigns(:source_rule))
  end

  test "should update source rule with all blank attributes" do
    put :update, id: @source_rule.to_param, source_id: sources(:two).to_param
    assert_not_nil assigns(:source_rule)
    assert_equal [], assigns(:source_rule).actions
    assert_equal [], assigns(:source_rule).users
    assert_equal false, assigns(:source_rule).blocked
    assert_redirected_to source_rule_path(assigns(:source_rule))
  end

  test "should not update source rule with invalid id" do
    put :update, id: -1, source_rule: @source_rule.attributes, source_id: sources(:two).to_param
    assert_nil assigns(:source_rule)
    assert_equal "Source Rule not found.", flash[:alert]
    assert_redirected_to root_path
  end

  test "should destroy source rule" do
    assert_difference('SourceRule.count', -1) do
      delete :destroy, id: @source_rule.to_param, source_id: sources(:two).to_param
    end

    assert_redirected_to source_path(assigns(:source))
  end

  test "should not destroy source rule with invalid id" do
    assert_difference('SourceRule.count', 0) do
      delete :destroy, id: -1, source_id: sources(:two).to_param
    end
    assert_nil assigns(:source_rule)
    assert_equal "Source Rule not found.", flash[:alert]
    assert_redirected_to root_path
  end
end
