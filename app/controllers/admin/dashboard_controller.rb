module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @admins_count = User.where(admin: true).count
      @suspended_users_count = User.where(suspended: true).count
      @folders_count = Folder.count
      @files_count = Cv.count
      @share_links_count = ShareLink.count
      @storage_bytes = ActiveStorage::Blob.sum(:byte_size)
      @recent_users = User.order(created_at: :desc).limit(6)
      @recent_share_links = ShareLink.includes(:user).order(created_at: :desc).limit(6)
    end
  end
end
