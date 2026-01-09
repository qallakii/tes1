class SearchController < ApplicationController
  before_action :require_login

  def index
    @query = params[:q].to_s.strip

    if @query.blank?
      @folders = Folder.none
      @cvs = Cv.none
      return
    end

    q = "%#{@query.downcase}%"

    @folders = current_user.folders
      .where("LOWER(name) LIKE ?", q)
      .order(updated_at: :desc)

    @cvs = current_user.cvs
      .joins(file_attachment: :blob)
      .with_attached_file
      .where("LOWER(cvs.title) LIKE ? OR LOWER(active_storage_blobs.filename) LIKE ?", q, q)
      .order(updated_at: :desc)
  end
end
