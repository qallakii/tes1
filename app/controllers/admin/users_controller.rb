module Admin
  class UsersController < BaseController
    def index
      @q = params[:q].to_s.strip
      @users = User.order(created_at: :desc)
      if @q.present?
        q = "%#{@q.downcase}%"
        @users = @users.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", q, q)
      end
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(base_admin_user_params)
      temporary_password = SecureRandom.urlsafe_base64(32)
      @user.password = temporary_password
      @user.password_confirmation = temporary_password
      @user.force_password_change = true

      if @user.save
        invite_url = edit_password_reset_url(@user.generate_password_reset_token!)
        email_status = deliver_link_email(:invite_link, @user, invite_url)

        flash[:notice] = email_status ? "User created and invite email sent." : "User created, but invite email delivery failed."
        flash[:admin_action_title] = "Invite link"
        flash[:admin_action_url] = invite_url
        redirect_to edit_admin_user_path(@user)
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @user = User.find(params[:id])
      load_user_stats
    end

    def update
      @user = User.find(params[:id])
      load_user_stats
      attrs = admin_user_params
      if attrs[:password].blank?
        attrs = attrs.except(:password, :password_confirmation)
      end

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "User updated."
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def send_invite
      user = User.find(params[:id])
      invite_url = edit_password_reset_url(user.generate_password_reset_token!)
      email_status = deliver_link_email(:invite_link, user, invite_url)

      flash[:notice] = email_status ? "Invite email sent." : "Invite link generated, but email delivery failed."
      flash[:admin_action_title] = "Invite link"
      flash[:admin_action_url] = invite_url
      redirect_back fallback_location: edit_admin_user_path(user)
    end

    def reset_password
      user = User.find(params[:id])
      reset_url = edit_password_reset_url(user.generate_password_reset_token!)
      email_status = deliver_link_email(:password_reset_link, user, reset_url)

      flash[:notice] = email_status ? "Password reset email sent." : "Password reset link generated, but email delivery failed."
      flash[:admin_action_title] = "Password reset link"
      flash[:admin_action_url] = reset_url
      redirect_back fallback_location: edit_admin_user_path(user)
    end

    def toggle_suspended
      user = User.find(params[:id])

      if current_user == user && !user.suspended?
        redirect_back fallback_location: admin_users_path, alert: "You cannot suspend your own current admin account."
        return
      end

      user.update!(suspended: !user.suspended?)
      redirect_back fallback_location: admin_users_path,
                    notice: (user.suspended? ? "User suspended." : "User reactivated.")
    end

    private

    def base_admin_user_params
      params.require(:user).permit(:name, :email, :admin)
    end

    def admin_user_params
      params.require(:user).permit(:name, :email, :admin, :password, :password_confirmation)
    end

    def load_user_stats
      @user_folders_count = @user.folders.count
      @user_files_count = @user.cvs.count
      @user_share_links_count = @user.share_links.count
      @user_storage_bytes = ActiveStorage::Blob.joins(:attachments)
                                             .where(active_storage_attachments: { record_type: "Cv", record_id: @user.cvs.select(:id) })
                                             .sum(:byte_size)
    end

    def deliver_link_email(mail_type, user, url)
      UserMailer.public_send(mail_type, user, url).deliver_now
      true
    rescue StandardError => e
      Rails.logger.error("[admin_users] #{mail_type} email failed for #{user.email}: #{e.class} #{e.message}")
      false
    end
  end
end
