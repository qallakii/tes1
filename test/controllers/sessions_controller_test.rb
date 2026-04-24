require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @temp_user = User.create!(
      name: "Temporary User",
      email: "temporary@example.com",
      password: "temporary123",
      password_confirmation: "temporary123",
      force_password_change: true
    )
  end

  test "login page does not offer public signup" do
    get login_path

    assert_response :success
    assert_no_match "Sign Up", response.body
    assert_match "Need access? Contact an administrator to receive an invite.", response.body
  end

  test "public signup routes are unavailable" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/signup", method: :get)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users", method: :post)
    end
  end

  test "temporary password login redirects to the password reset form" do
    post login_path, params: { email: @temp_user.email, password: "temporary123" }

    @temp_user.reload

    assert_redirected_to edit_password_reset_path(@temp_user.reset_password_token)
    assert_equal "You must change your temporary password before continuing.", flash[:alert]
    assert_not_nil @temp_user.reset_password_token
  end
end
