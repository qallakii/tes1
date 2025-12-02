class ShareLinksController < ApplicationController
  before_action :set_folder, only: [:create]
  before_action :set_share_link, only: [:show]

  # List all share links
  def index
    @share_links = ShareLink.all
  end

  # Create a new share link
  def create
    @share_link = @folder.share_links.create
    redirect_to share_link_path(@share_link), notice: "Share link created! Copy the URL below."
  end

  # Access shared folder
  def show
    if @share_link.expired?
      redirect_to root_path, alert: "This share link has expired."
    else
      @folder = @share_link.folder
      @cvs = @folder.cvs
    end
  end

  private

  def set_folder
    @folder = Folder.find(params[:folder_id])
  end

  def set_share_link
    @share_link = ShareLink.find_by!(token: params[:id])
  end
end
