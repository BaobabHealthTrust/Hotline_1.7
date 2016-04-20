require 'test_helper'

class ReportControllerTest < ActionController::TestCase
  test "should get patient_analysis" do
    get :patient_analysis
    assert_response :success
  end

end
