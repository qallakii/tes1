require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      admin: true
    )
  end

  test "admin can create a user account" do
    post login_path, params: { email: @admin.email, password: "password123" }

    assert_difference("User.count", 1) do
      post admin_users_path, params: {
        password_mode: "temporary",
        temporary_password: "temporary123",
        user: {
          name: "Invited User",
          email: "invited@example.com",
          admin: "0"
        }
      }
    end

    user = User.order(:created_at).last

    assert_redirected_to edit_admin_user_path(user)
    assert user.force_password_change?
  end
end
