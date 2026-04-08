class PasswordResetsController < ApplicationController
  before_action :set_user_by_token

  def edit
    if @user.suspended?
      redirect_to login_path, alert: "This account has been suspended."
      return
    end

    return if @user.password_reset_period_valid?

    redirect_to login_path, alert: "This password link has expired."
  end

  def update
    if @user.suspended?
      redirect_to login_path, alert: "This account has been suspended."
      return
    end

    unless @user.password_reset_period_valid?
      redirect_to login_path, alert: "This password link has expired."
      return
    end

    if @user.update(password_reset_params)
      @user.clear_password_reset_token!
      @user.clear_password_change_requirement! if @user.force_password_change?
      session[:user_id] = @user.id
      redirect_to(session.delete(:return_to).presence || dashboard_path, notice: "Password updated.")
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by!(reset_password_token: params[:token])
  end

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
