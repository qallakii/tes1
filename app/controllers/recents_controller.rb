class RecentsController < ApplicationController
  before_action :require_login

  def index
    @recent_cvs = current_user
      .cvs
      .includes(:folder)
      .order(updated_at: :desc)
      .limit(50)
  end
end
