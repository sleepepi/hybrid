require 'test_helper'

class BuildingSearchTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    @valid = users(:valid)
    sign_in_as(@valid, "123456", "valid-2@example.com")
  end

  test "should create new search, add concepts, and keep track of query concept change history" do
    get new_query_path
    assert_not_nil assigns(:query)

    post query_concepts_path(query_id: assigns(:query).id, variable_id: variables(:numeric)), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 1, assigns(:query).history_position
    assert_equal 1, assigns(:query).history.size

    patch query_concept_path(query_id: assigns(:query).id, id: assigns(:query).query_concepts.first.id, query_concept: { value: 30 }), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 2, assigns(:query).history_position
    assert_equal 2, assigns(:query).history.size

    post undo_query_path(id: assigns(:query).id), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 1, assigns(:query).history_position
    assert_equal 2, assigns(:query).history.size

    post undo_query_path(id: assigns(:query).id), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 0, assigns(:query).query_concepts.size
    assert_equal 0, assigns(:query).history_position
    assert_equal 2, assigns(:query).history.size

    post query_concepts_path(query_id: assigns(:query).id, variable_id: variables(:choices)), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 5, assigns(:query).history_position
    assert_equal 5, assigns(:query).history.size

    delete query_concept_path(query_id: assigns(:query).id, id: assigns(:query).query_concepts.first.id), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 0, assigns(:query).query_concepts.size
    assert_equal 6, assigns(:query).history_position
    assert_equal 6, assigns(:query).history.size

    post undo_query_path(id: assigns(:query).id), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 1, assigns(:query).query_concepts.size
    assert_equal 5, assigns(:query).history_position
    assert_equal 6, assigns(:query).history.size

    post query_concepts_path(query_id: assigns(:query).id, variable_id: variables(:gender)), format: 'js'

    assert_not_nil assigns(:query)
    assert_equal 2, assigns(:query).query_concepts.size
    assert_equal 8, assigns(:query).history_position
    assert_equal 8, assigns(:query).history.size
  end
end
