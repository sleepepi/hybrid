require 'test_helper'

class MappingTest < ActiveSupport::TestCase
  test "mapped? returns true if the mapping is mapped" do
    assert_equal true, mappings(:mapped).mapped?
  end

  test "mapped? returns false if the mapping is not mapped" do
    assert_equal false, mappings(:three).mapped?
  end

  test "set_status! sets status to unmapped for boolean mapping with no values" do
    mappings(:one).set_status!(users(:admin))
    assert_equal 'unmapped', mappings(:one).status
  end

  test "set_status! a continuous concept is unmapped if it does not have units" do
    mappings(:continuous_without_units).set_status!(users(:admin))
    assert_equal 'unmapped', mappings(:continuous_without_units).status
  end

  test "set_status! a continuous concept is mapped if it has units" do
    mappings(:continuous_with_units).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:continuous_with_units).status
  end

  test "set_status! a categorical with at least one of its values mapped is considered mapped" do
    mappings(:categorical_with_values).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:categorical_with_values).status
  end

  test "set_status! a date mapping is considered mapped" do
    mappings(:datetime).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:datetime).status
  end

  test "set_status! an identifier mapping is considered mapped" do
    mappings(:identifier).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:identifier).status
  end

  test "set_status! a filelocator mapping is considered mapped" do
    mappings(:filelocator).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:filelocator).status
  end

  test "set_status! a freetext mapping is considered mapped" do
    mappings(:freetext).set_status!(users(:admin))
    assert_equal 'mapped', mappings(:freetext).status
  end

  test "set_status! an invalid mapped concept is considered unmapped" do
    mappings(:invalid).set_status!(users(:admin))
    assert_equal 'unmapped', mappings(:invalid).status
  end

  test "set_status! an mapping referencing a deleted concept is considered outdated" do
    mappings(:nonexistent_concept).set_status!(users(:admin))
    assert_equal 'outdated', mappings(:nonexistent_concept).status
  end

  test "set_status! an mapping without a concept is considered unmapped" do
    mappings(:no_concept).set_status!(users(:admin))
    assert_equal 'unmapped', mappings(:no_concept).status
  end

  test "all_concepts returns an array of values" do
    assert mappings(:one).all_concepts.is_a?(Array)
  end

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

  test "column_statistics_given_values returns a string if values are given" do
    assert mappings(:one).column_statistics_given_values([1,2,3,4]).is_a?(String)
  end

  test "column_statistics_given_values returns a string even if the concept type is not supported" do
    assert mappings(:invalid).column_statistics_given_values([1,2,3,4]).is_a?(String)
  end

  test "column_statistics_given_values returns a string if no values are given" do
    assert mappings(:one).column_statistics_given_values([]).is_a?(String)
  end

  test "column_statistics_given_values returns a string if values are given for continuous concept" do
    assert mappings(:continuous_with_units).column_statistics_given_values([1,2,3,4,nil]).is_a?(String)
  end

  test "generate_derived! for a continuous mapping increases the amount of derived concepts" do
    source = mappings(:continuous_with_units).source
    orig_mappings = source.derived_concepts.size
    mappings(:continuous_with_units).generate_derived!
    assert_equal orig_mappings + 2, source.derived_concepts.size
  end

  test "abstract_value for query concepts" do
    assert mappings(:mapped_boolean).abstract_value(query_concepts(:with_boolean_data)).kind_of?(Array)
    assert mappings(:mapped_boolean).abstract_value(query_concepts(:with_boolean_data_negated)).kind_of?(Array)
    assert mappings(:mapped_continuous).abstract_value(query_concepts(:with_data)).kind_of?(Array)
    assert mappings(:mapped_continuous).abstract_value(query_concepts(:with_data_negated)).kind_of?(Array)
    assert mappings(:mapped_categorical).abstract_value(query_concepts(:with_categorical_data)).kind_of?(Array)
    assert mappings(:mapped_categorical).abstract_value(query_concepts(:with_categorical_data_negated)).kind_of?(Array)
    assert mappings(:mapped_categorical).abstract_value(query_concepts(:with_categorical_data_true_false)).kind_of?(Array)
    assert mappings(:mapped_date).abstract_value(query_concepts(:with_date_data)).kind_of?(Array)
    assert mappings(:nonexistent_concept).abstract_value(query_concepts(:with_boolean_data)).kind_of?(Array)
  end

  test "human_normalized_value converts mappings to human readable format" do
    assert_equal mappings(:boolean_male).concept.human_name, mappings(:categorical_with_values).human_normalized_value('m')
    assert_equal 'true', mappings(:boolean_male).human_normalized_value('m')
    assert_equal '2011', mappings(:mapped_date).human_normalized_value('2011')
    assert_equal 'Strange Value', mappings(:boolean_female).human_normalized_value('f')
  end

  test "uniq_normalized_value converts values to uniq strings" do
    assert_equal mappings(:boolean_male).concept.id, mappings(:categorical_with_values).uniq_normalized_value('m')
    # assert_equal 'true', mappings(:boolean_male).uniq_normalized_value('m')
    assert_equal '2011', mappings(:mapped_date).uniq_normalized_value('2011')
    assert_equal 'Strange Value', mappings(:boolean_female).uniq_normalized_value('f')
  end

  test "should return human readable units" do
    assert_equal 'year', mappings(:mapped_with_human_units).human_units
  end

  test "user_can_view? should show if the user can view the mapping" do
    assert_equal false, mappings(:mapped_boolean).user_can_view?(users(:valid), ['view limited data distribution'])
  end

  test "should permanently delete mapping" do
    assert_difference('Mapping.count', -1) do
      mappings(:mapped_boolean).destroy(true)
    end
  end
end
