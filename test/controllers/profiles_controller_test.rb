require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Jane Doe",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "redirects unauthenticated users to login" do
    get profile_path

    assert_redirected_to login_path
  end

  test "shows the current user's profile" do
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    get profile_path

    assert_response :success
    assert_match "Jane Doe", response.body
    assert_match "Edit profile", response.body
  end

  test "updates profile details" do
    post login_path, params: { email: @user.email, password: "password123" }

    patch profile_path, params: {
      user: {
        name: "Jane Smith",
        email: "jane.smith@example.com",
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to profile_path
    assert_equal "Jane Smith", @user.reload.name
    assert_equal "jane.smith@example.com", @user.reload.email
  end
end
