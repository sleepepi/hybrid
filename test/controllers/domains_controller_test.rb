require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  setup do
    login(users(:admin))
    @domain = domains(:one)
  end

  test "should get index" do
    get :index, dictionary_id: dictionaries(:one)
    assert_response :success
    assert_not_nil assigns(:domains)
  end

  test "should show domain" do
    get :show, dictionary_id: dictionaries(:one), id: @domain
    assert_response :success
  end
end
