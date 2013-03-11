require 'test_helper'

class ReportConceptTest < ActiveSupport::TestCase

  test "should get external concept information" do
    assert report_concepts(:external_concept).external_concept_information(users(:admin)).kind_of?(Hash)
  end
end
