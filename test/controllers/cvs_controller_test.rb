require "test_helper"

class CvsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "CV User",
      email: "cvs@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @folder = @user.folders.create!(name: "Candidate Files")
    @cv = @user.cvs.create!(folder: @folder, title: "Existing CV")
  end

  test "new redirects unauthenticated users" do
    get new_folder_cv_path(@folder)

    assert_redirected_to login_path
  end

  test "authenticated user can open new cv page" do
    post login_path, params: { email: @user.email, password: "password123" }

    get new_folder_cv_path(@folder)

    assert_response :success
  end

  test "authenticated user can upload a cv" do
    post login_path, params: { email: @user.email, password: "password123" }

    file = fixture_file_upload("sample_resume.txt", "text/plain")

    assert_difference("Cv.count", 1) do
      post folder_cvs_path(@folder), params: {
        cv: {
          files: [ file ],
          paths: [ "sample_resume.txt" ]
        }
      }
    end

    assert_redirected_to folder_path(@folder)
  end

  test "uploading a folder keeps the selected top-level folder" do
    post login_path, params: { email: @user.email, password: "password123" }

    file = fixture_file_upload("sample_resume.txt", "text/plain")

    assert_difference("Cv.count", 1) do
      assert_difference("Folder.count", 1) do
        post folder_cvs_path(@folder), params: {
          cv: {
            files: [ file ],
            paths: [ "Team Docs/sample_resume.txt" ]
          }
        }
      end
    end

    uploaded_folder = @user.folders.find_by!(name: "Team Docs", parent_id: @folder.id)
    assert_equal uploaded_folder.id, Cv.order(:created_at).last.folder_id
    assert_redirected_to folder_path(@folder)
  end

  test "authenticated user can view a cv" do
    post login_path, params: { email: @user.email, password: "password123" }

    get folder_cv_path(@folder, @cv)

    assert_response :success
    assert_match "Existing CV", response.body
  end
end
