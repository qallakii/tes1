require "test_helper"

class ShareLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Share Owner",
      email: "share-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @folder = @user.folders.create!(name: "Shared Folder")
    @share_link = @user.share_links.create!(folder: @folder)
  end

  test "public share page is accessible by token" do
    get public_share_path(@share_link.token)

    assert_response :success
    assert_match "Shared Folder", response.body
  end

  test "authenticated user can create a share link for a folder" do
    post login_path, params: { email: @user.email, password: "password123" }

    assert_difference("ShareLink.count", 1) do
      post share_links_path, params: { folder_id: @folder.id }
    end

    assert_redirected_to share_links_path
  end
end
