require 'test_helper'

class BuildingSearchTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    @valid = users(:valid)
    sign_in_as(@valid, "123456", "valid-2@example.com")
  end

  test "should create new search, add search criteria, and keep track of search history" do
    get new_search_path
    assert_not_nil assigns(:search)

    post criteria_path(search_id: assigns(:search).id, variable_id: variables(:numeric)), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 1, assigns(:search).history_position
    assert_equal 1, assigns(:search).history.size

    patch criterium_path(search_id: assigns(:search).id, id: assigns(:search).criteria.first.id, criterium: { value: 30 }), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 2, assigns(:search).history_position
    assert_equal 2, assigns(:search).history.size

    post undo_search_path(id: assigns(:search).id), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 1, assigns(:search).history_position
    assert_equal 2, assigns(:search).history.size

    post undo_search_path(id: assigns(:search).id), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 0, assigns(:search).criteria.size
    assert_equal 0, assigns(:search).history_position
    assert_equal 2, assigns(:search).history.size

    post criteria_path(search_id: assigns(:search).id, variable_id: variables(:choices)), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 5, assigns(:search).history_position
    assert_equal 5, assigns(:search).history.size

    delete criterium_path(search_id: assigns(:search).id, id: assigns(:search).criteria.first.id), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 0, assigns(:search).criteria.size
    assert_equal 6, assigns(:search).history_position
    assert_equal 6, assigns(:search).history.size

    post undo_search_path(id: assigns(:search).id), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 1, assigns(:search).criteria.size
    assert_equal 5, assigns(:search).history_position
    assert_equal 6, assigns(:search).history.size

    post criteria_path(search_id: assigns(:search).id, variable_id: variables(:gender)), format: 'js'

    assert_not_nil assigns(:search)
    assert_equal 2, assigns(:search).criteria.size
    assert_equal 8, assigns(:search).history_position
    assert_equal 8, assigns(:search).history.size
  end
end
