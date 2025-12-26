class ShareLinksController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: [:create]
  before_action :set_share_link, only: [:show, :destroy]

  def index
    @share_links = ShareLink.all.includes(:folder)
  end

  def create
    @share_link = @folder.share_links.create
    flash[:notice] = "Share link created! Copy the URL below."
    redirect_to share_link_path(@share_link)
  end

  def show
    if @share_link.expired?
      flash[:alert] = "This share link has expired."
      redirect_to root_path
    else
      @folder = @share_link.folder
      @cvs = @folder.cvs
    end
  end

  def destroy
    @share_link.destroy
    flash[:notice] = "Share link deleted."
    redirect_to share_links_path
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def set_share_link
    @share_link = ShareLink.find_by!(token: params[:id])
  end
end
