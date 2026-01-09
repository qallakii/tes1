class SearchController < ApplicationController
  before_action :require_login

  def index
    @query = params[:q].to_s.strip

    @folders = current_user.folders
    @cvs = Cv.joins(:folder).where(folders: { user_id: current_user.id })

    if @query.present?
      q = "%#{@query.downcase}%"
      @folders = @folders.where("LOWER(name) LIKE ?", q)

      @cvs = @cvs.where(
        "LOWER(cvs.title) LIKE ? OR LOWER(active_storage_blobs.filename) LIKE ?",
        q, q
      ).joins(file_attachment: :blob)
    else
      @folders = []
      @cvs = []
    end
  end
end
