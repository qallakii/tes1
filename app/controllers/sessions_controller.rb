class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.suspended?
      flash.now[:alert] = "This account has been suspended."
      render :new, status: :unprocessable_entity
    elsif user&.authenticate(params[:password])
      if user.force_password_change?
        user.generate_password_reset_token!
        redirect_to password_reset_path(user.reset_password_token), alert: "You must change your temporary password before continuing."
      else
        session[:user_id] = user.id
        redirect_to(session.delete(:return_to).presence || dashboard_path)
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out successfully"
  end
end
