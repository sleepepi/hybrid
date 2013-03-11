require 'test_helper'

class QueryConceptTest < ActiveSupport::TestCase
  test "linked sql for query concept" do
    linked_source = sources(:linked_source_a)
    current_user = users(:admin)
    sql_codes_hash = linked_source.sql_codes(current_user)
    result_hash = query_concepts(:linked_concept).linked_sql(current_user, linked_source)
    assert_not_nil result_hash
    assert_equal "(#{source_joins(:three).from_table}.#{sql_codes_hash[:open]}#{source_joins(:three).from_column}#{sql_codes_hash[:close]} IN (1, 5))", result_hash[:conditions]
    assert_equal ['table'], result_hash[:tables]
    assert_equal '', result_hash[:error]
  end
  
  test "linked sql for reverse linked query concept" do
    linked_source = sources(:linked_source_b)
    current_user = users(:admin)
    sql_codes_hash = linked_source.sql_codes(current_user)
    result_hash = query_concepts(:linked_concept).linked_sql(current_user, linked_source)
    assert_not_nil result_hash
    assert_equal "(#{source_joins(:three).to_table}.#{sql_codes_hash[:open]}#{source_joins(:three).to_column}#{sql_codes_hash[:close]} IN (1, 5))", result_hash[:conditions]
    assert_equal ['table'], result_hash[:tables]
    assert_equal '', result_hash[:error]
  end
end
