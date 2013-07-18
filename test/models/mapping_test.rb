require 'test_helper'

class MappingTest < ActiveSupport::TestCase

  test "column_values returns an array of values" do
    assert mappings(:one).column_values(users(:admin)).is_a?(Array)
  end

  test "all_values_for_column returns an array of hash with keys: values, and error" do
    result = mappings(:one).all_values_for_column(users(:admin))
    assert result.is_a?(Hash)
    assert result[:values].is_a?(Array)
    assert result[:error].is_a?(String)
  end

  test "all_values_for_column returns an empty array for a user without adequate permissions" do
    result = mappings(:one).all_values_for_column(users(:valid))
    assert result.is_a?(Hash)
    assert_equal [], result[:values]
    assert !result[:error].blank?
  end

  test "abstract_value for query concepts" do
    assert mappings(:calculation).abstract_value(query_concepts(:with_data)).kind_of?(Array)
    assert mappings(:calculation).abstract_value(query_concepts(:with_data_negated)).kind_of?(Array)
    assert mappings(:mapped_choices).abstract_value(query_concepts(:with_choices_data)).kind_of?(Array)
    assert mappings(:mapped_choices).abstract_value(query_concepts(:with_choices_data_negated)).kind_of?(Array)
    assert mappings(:mapped_choices).abstract_value(query_concepts(:with_choices_data_true_false)).kind_of?(Array)
    assert mappings(:mapped_date).abstract_value(query_concepts(:with_date_data)).kind_of?(Array)
  end

  test "human_normalized_value converts mappings to human readable format" do
    assert_equal 'Male', mappings(:choices_with_values).human_normalized_value('1')
    assert_equal '2011', mappings(:mapped_date).human_normalized_value('2011')
  end

  test "user_can_view? should show if the user can view the mapping" do
    assert_equal false, mappings(:mapped_date).user_can_view?(users(:valid), ['view limited data distribution'])
  end
end
