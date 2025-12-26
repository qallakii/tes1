class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  before_action :set_flash

  # User Authentication
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section"
      redirect_to login_path
    end
  end

  private

  # Handle Record Not Found globally
  rescue_from ActiveRecord::RecordNotFound do
    flash[:alert] = "Record not found."
    redirect_to root_path
  end

  def set_flash
    # make flash available for layouts
    @flash_notice = flash[:notice]
    @flash_alert = flash[:alert]
  end
end
