class RecentsController < ApplicationController
  before_action :require_login

  def index
    @page = pagination_page
    @per_page = pagination_per_page
    recent_cvs_scope = current_user
      .cvs
      .includes(:folder)
      .order(updated_at: :desc)

    @recent_cvs = recent_cvs_scope.page(@page).per(@per_page)
    clamped_page = clamp_pagination_page(@page, @recent_cvs.total_count, @per_page)

    if clamped_page != @page
      @page = clamped_page
      @recent_cvs = recent_cvs_scope
        .page(@page)
        .per(@per_page)
    end
  end
end
