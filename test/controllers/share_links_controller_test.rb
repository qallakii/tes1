require "test_helper"

class ShareLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Share Owner",
      email: "share-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @recipient = User.create!(
      name: "Share Recipient",
      email: "share-recipient@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @folder = @user.folders.create!(name: "Shared Folder")
    @share_link = @user.share_links.create!(folder: @folder, user: @user)
  end

  test "public share page is accessible by token" do
    get public_share_path(@share_link.token)

    assert_response :success
    assert_match "Shared Folder", response.body
  end

  test "public folder share opens at folder level before showing files" do
    cv = @folder.cvs.create!(user: @user)
    cv.file.attach(fixture_file_upload("sample_resume.txt", "text/plain"))
    cv.save!

    get public_share_path(@share_link.token)

    assert_response :success
    assert_match "Shared Folder", response.body
    assert_no_match "sample_resume", response.body

    get public_share_path(@share_link.token, folder_id: @folder.id)

    assert_response :success
    assert_match "sample_resume", response.body
  end

  test "public folder share allows downloading the folder as a zip" do
    cv = @folder.cvs.create!(user: @user)
    cv.file.attach(fixture_file_upload("sample_resume.txt", "text/plain"))
    cv.save!

    get folder_download_share_link_path(@share_link, folder_id: @folder.id)

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_match(/attachment/, response.headers["Content-Disposition"])
  end

  test "authenticated user can create a share link for a folder" do
    post login_path, params: { email: @user.email, password: "password123" }

    assert_difference("ShareLink.count", 1) do
      post share_links_path, params: { folder_id: @folder.id }
    end

    assert_redirected_to share_links_path
  end

  test "bulk item sharing stores editor permission for specific people" do
    post login_path, params: { email: @user.email, password: "password123" }

    assert_difference("ShareLink.count", 1) do
      post bulk_create_items_share_links_path,
        params: {
          folder_ids: [ @folder.id ],
          share_audience: "specific_people",
          share_emails: @recipient.email,
          share_permission: "editor"
        },
        as: :json
    end

    assert_response :success
    link = ShareLink.order(:created_at).last
    assert_equal "editor", link.share_link_accesses.find_by!(user: @recipient).permission
  end

  test "selection details lists existing recipients and permissions" do
    ShareLinkAccess.create!(share_link: @share_link, user: @recipient, permission: "editor")
    post login_path, params: { email: @user.email, password: "password123" }

    post selection_details_share_links_path,
      params: { folder_ids: [ @folder.id ] },
      as: :json

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "This folder", body["scope_label"]
    assert_includes body["entries"], {
      "kind" => "user",
      "label" => @recipient.email,
      "name" => @recipient.name,
      "permission" => "editor"
    }
  end
end
