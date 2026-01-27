class SearchController < ApplicationController
  before_action :require_login

  def index
    @q = params[:q].to_s.strip
    @folders = []
    @cvs = []

    return if @q.blank?

    @folders = current_user.folders
      .where("name ILIKE ?", "%#{@q}%")
      .order(updated_at: :desc)
      .limit(50)

    @cvs = current_user.cvs
      .joins(:folder)
      .where("cvs.title ILIKE ?", "%#{@q}%")
      .includes(:folder, file_attachment: :blob)
      .order(updated_at: :desc)
      .limit(50)
  end
end
