require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  test "should get file type count" do
    assert_equal true, searches(:one).file_type_count(users(:admin), file_types(:one)).kind_of?(Hash)
  end

  test "should get available files" do
    assert_equal true, searches(:one).available_files(users(:admin)).kind_of?(Hash)
  end
end
