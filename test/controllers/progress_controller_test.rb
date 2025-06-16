require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get Progress_index_url
    assert_response :success
  end
end
