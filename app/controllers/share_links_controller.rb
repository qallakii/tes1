class ShareLinksController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_share_link, only: :show

  def create
    folder = current_user.folders.find(params[:folder_id])
    share_link = folder.share_links.create!
    redirect_to folder_path(folder), notice: "Share link created"
  end

  def show
    @folder = @share_link.folder
    @cvs = @folder.cvs
  end

  private

  def set_share_link
    @share_link = ShareLink.find_by!(token: params[:token])
  end
end
