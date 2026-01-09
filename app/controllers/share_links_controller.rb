class ShareLinksController < ApplicationController
  before_action :require_login, except: :show
  before_action :set_share_link, only: :show

  def index
    # show only links for folders that belong to current user
    @share_links = ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
      .order(created_at: :desc)
  end

  def create
    folder = current_user.folders.find(params[:folder_id])
    share_link = folder.share_links.create!
    redirect_to folder_path(folder), notice: "Share link created"
  end

  def destroy
    share_link = ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
      .find(params[:id])

    share_link.destroy
    redirect_to share_links_path, notice: "Share link removed"
  end

  def show
    @folder = @share_link.folder
    @cvs = @folder.cvs.with_attached_file.order(updated_at: :desc)
  end

  private

  def set_share_link
    @share_link = ShareLink.find_by!(token: params[:token])
  end
end
