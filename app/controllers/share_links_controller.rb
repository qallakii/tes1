class ShareLinksController < ApplicationController
  before_action :require_login, except: :show

  def index
    @share_links = ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
      .includes(:folder)
      .order(created_at: :desc)
  end

  def new
    @folders = current_user.folders.order(updated_at: :desc)

    if params[:folder_id].present?
      @folder = current_user.folders.find(params[:folder_id])
      @cvs = @folder.cvs.with_attached_file.order(updated_at: :desc)
    end
  end


  def create
    folder = current_user.folders.find(params[:folder_id])

    expires_at =
      if params[:expires_at].present?
        Time.zone.parse(params[:expires_at])
      else
        nil
      end

    share_link = folder.share_links.create!(
      expires_at: expires_at
    )

    cv_ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)
    if cv_ids.any?
      allowed_ids = folder.cvs.where(id: cv_ids).pluck(:id)
      allowed_ids.each do |id|
        ShareLinkCv.create!(share_link: share_link, cv_id: id)
      end
    end

    url = share_link_url(share_link.token)

    redirect_to(params[:return_to].presence || share_links_path,
      notice: "Share link created: #{url}"
    )
  end

  def destroy
    share_link = ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
      .find(params[:id])

    share_link.destroy
    redirect_to share_links_path, notice: "Share link deleted."
  end

  def show
    @share_link = ShareLink.includes(:folder, :cvs).find_by!(token: params[:id])

    if @share_link.expires_at.present? && @share_link.expires_at < Time.current
      render plain: "This share link has expired.", status: :gone
      return
    end

    @folder = @share_link.folder

    @cvs =
      if @share_link.cvs.any?
        @share_link.cvs.with_attached_file.order(updated_at: :desc)
      else
        @folder.cvs.with_attached_file.order(updated_at: :desc)
      end
  end
end
