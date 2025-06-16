require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get progress_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    sign_out @user
    get progress_url
    assert_redirected_to new_user_session_path
  end
end
