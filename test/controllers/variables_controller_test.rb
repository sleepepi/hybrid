require 'test_helper'

class VariablesControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @variable = variables(:one)
  end

  test "should get index" do
    get :index, dictionary_id: dictionaries(:one)
    assert_response :success
    assert_not_nil assigns(:variables)
  end

  test "should show variable" do
    get :show, dictionary_id: dictionaries(:one), id: @variable
    assert_response :success
  end
end
