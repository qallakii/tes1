module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @folders_count = Folder.count
      @files_count = Cv.count
      @share_links_count = ShareLink.count
      @storage_bytes = ActiveStorage::Blob.sum(:byte_size)
    end
  end
end
