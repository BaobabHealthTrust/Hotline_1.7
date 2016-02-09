require 'test_helper'

class PersonControllerTest < ActionController::TestCase
  test "should get demographics" do
    get :demographics
    assert_response :success
  end

end
