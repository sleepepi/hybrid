require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  test "should get file type count" do
    assert_equal true, queries(:one).file_type_count(users(:admin), file_types(:one)).kind_of?(Hash)
  end

  test "should get available files" do
    assert_equal true, queries(:one).available_files(users(:admin)).kind_of?(Hash)
  end
end
