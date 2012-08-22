require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  test "should show if user has action group" do
    assert_equal true, sources(:two).user_has_action_group?(users(:admin), "All Write")
    assert_equal false, sources(:two).user_has_action_group?(users(:valid), "All Write")
  end
  
  test "should show false if the action group does not exist" do
    assert_equal false, sources(:two).user_has_action_group?(users(:admin), "All Code")
  end
  
  test "should show join conditions given an array of tables" do
    result_hash = sources(:two).join_conditions(['table', 'table2', 'table3'], users(:admin))
    assert result_hash.kind_of?(Hash)
    assert result_hash[:result].kind_of?(Array)
    assert result_hash[:errors].kind_of?(Array)
    assert result_hash[:result].size > 0
    assert result_hash[:errors].size > 0
  end
  
  test "should generate derived mappings" do
    sources(:two).generate_derived_mappings!
    assert_equal 1, sources(:two).mappings.status('derived').size
  end
  
end
