require "test_helper"

class RatingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Rating User",
      email: "ratings@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @folder = @user.folders.create!(name: "Rated Folder")
    @cv = @user.cvs.create!(folder: @folder, title: "Sample CV")
  end

  test "ratings index redirects unauthenticated users" do
    get ratings_path

    assert_redirected_to login_path
  end

  test "authenticated user can create a rating for a cv" do
    post login_path, params: { email: @user.email, password: "password123" }

    assert_difference("Rating.count", 1) do
      post folder_cv_ratings_path(@folder, @cv), params: {
        rating: {
          stars: 5,
          comment: "Great file"
        }
      }
    end

    assert_redirected_to folder_cv_path(@folder, @cv)
  end
end
