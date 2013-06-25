require 'test_helper'

class RulesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @source = sources(:two)
    @rule = rules(:one)
  end

  test "should get index" do
    get :index, source_id: @source
    assert_not_nil assigns(:rules)
    assert_response :success
  end

  test "should not get index for invalid source" do
    get :index, source_id: -1
    assert_nil assigns(:rules)
    assert_nil assigns(:source)
    assert_redirected_to root_path
  end

  test "should get new" do
    get :new, source_id: @source
    assert_response :success
  end

  test "should create source rule" do
    assert_difference('Rule.count') do
      post :create, source_id: @source, rule: @rule.attributes
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:rule)
    assert_redirected_to source_rule_path(assigns(:rule).source, assigns(:rule))
  end

  test "should create source rule with user tokens" do
    assert_difference('Rule.count') do
      post :create, source_id: @source, rule: { actions: ['edit data source rules', 'get count'], user_tokens: "#{users(:admin).to_param},#{users(:pending).to_param}", blocked: false }
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:rule)
    assert_equal [users(:admin).to_param.to_s, users(:pending).to_param.to_s], assigns(:rule).users
    assert_redirected_to source_rule_path(assigns(:rule).source, assigns(:rule))
  end

  test "should create source rule with all blank attributes" do
    assert_difference('Rule.count') do
      post :create, source_id: @source
    end
    assert_not_nil assigns(:source)
    assert_not_nil assigns(:rule)
    assert_equal [], assigns(:rule).actions
    assert_equal [], assigns(:rule).users
    assert_equal false, assigns(:rule).blocked
    assert_redirected_to source_rule_path(assigns(:rule).source, assigns(:rule))
  end

  test "should not create source rule for invalid source" do
    assert_difference('Rule.count', 0) do
      post :create, source_id: -1, rule: @rule.attributes
    end
    assert_nil assigns(:source)
    assert_nil assigns(:rule)
    assert_redirected_to root_path
  end

  test "should show source rule" do
    get :show, id: @rule, source_id: @source
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @rule, source_id: @source
    assert_response :success
  end

  test "should update source rule" do
    put :update, id: @rule, source_id: @source, rule: { user_tokens: '', description: '', name: '', blocked: true, rules: { 'get_count' => '1' } }
    assert_redirected_to source_rule_path(assigns(:rule).source, assigns(:rule))
  end

  test "should update source rule with all blank attributes" do
    put :update, id: @rule, source_id: @source
    assert_not_nil assigns(:rule)
    assert_equal [], assigns(:rule).actions
    assert_equal [], assigns(:rule).users
    assert_equal false, assigns(:rule).blocked
    assert_redirected_to source_rule_path(assigns(:rule).source, assigns(:rule))
  end

  test "should not update source rule with invalid id" do
    put :update, id: -1, source_id: @source, rule: @rule.attributes
    assert_nil assigns(:rule)
    assert_redirected_to source_rules_path(assigns(:source))
  end

  test "should destroy source rule" do
    assert_difference('Rule.count', -1) do
      delete :destroy, id: @rule, source_id: @source
    end

    assert_redirected_to source_rules_path(assigns(:source).id)
  end

  test "should not destroy source rule with invalid id" do
    assert_difference('Rule.count', 0) do
      delete :destroy, id: -1, source_id: @source
    end
    assert_nil assigns(:rule)
    assert_redirected_to source_rules_path(assigns(:source))
  end
end
