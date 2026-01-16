module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc)
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])

      if @user.update(admin_user_params)
        redirect_to admin_users_path, notice: "User updated."
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def admin_user_params
      params.require(:user).permit(:name, :email, :admin)
    end
  end
end
