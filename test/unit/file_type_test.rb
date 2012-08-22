require 'test_helper'

class FileTypeTest < ActiveSupport::TestCase

  test "should allow user to download file type" do
    assert_equal true, file_types(:one).user_can_download?(users(:admin), [sources(:two)])
  end

  test "should not allow user to download file type" do
    assert_equal false, file_types(:one).user_can_download?(users(:valid), [sources(:two)])
  end

end
