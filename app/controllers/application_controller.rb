class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if defined?(@current_user)

    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    else
      @current_user = nil
    end
  end

  def logged_in?
    current_user.present?
  end

  # ✅ Use this everywhere to protect authenticated pages
  def require_login
    return if logged_in?

    session[:return_to] = request.fullpath if request.get?
    redirect_to login_path, alert: "Please log in to continue."
  end

  def require_admin
    require_login
    return if performed?
    return if current_user&.admin?

    redirect_to dashboard_path, alert: "Admin access required."
  end
end
