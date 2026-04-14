require "test_helper"

class FoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Folder User",
      email: "folders@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "dashboard redirects unauthenticated users" do
    get dashboard_path

    assert_redirected_to login_path
  end

  test "new folder page loads for authenticated users" do
    post login_path, params: { email: @user.email, password: "password123" }

    get new_folder_path

    assert_response :success
    assert_match "New", response.body
  end
end
