class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # Allow updating name/email, and optionally password
    attrs = params.require(:user).permit(:name, :email, :password, :password_confirmation)

    # If password fields are blank, don't change password
    if attrs[:password].blank?
      attrs = attrs.except(:password, :password_confirmation)
    end

    if @user.update(attrs)
      redirect_to profile_path, notice: "Profile updated."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end
