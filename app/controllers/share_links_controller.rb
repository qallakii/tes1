class ShareLinksController < ApplicationController
  before_action :require_login, except: [ :show, :preview, :download, :unlock ]
  before_action :set_share_link_by_token, only: [ :show, :preview, :download, :unlock ]
  before_action :enforce_require_login_if_needed!, only: [ :show, :preview, :download, :unlock ]
  before_action :enforce_not_disabled!, only: [ :show, :preview, :download, :unlock ]
  before_action :enforce_password_if_needed!, only: [ :show, :preview, :download ]

  def index
    @share_links = ShareLink
      .left_joins(:folder)
      .where("folders.user_id = ? OR share_links.user_id = ?", current_user.id, current_user.id)
      .distinct
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

    expires_at = nil
      raw_expires = params[:expires_at].to_s.strip

      if raw_expires.present?
        expires_at = Time.zone.parse(raw_expires)
        if expires_at.nil?
          redirect_back fallback_location: dashboard_path, alert: "Invalid expiry date."
          return
        end
      end

    share_link = ShareLink.new(expires_at: expires_at, folder: folder)
    share_link.user_id = current_user.id if ShareLink.column_names.include?("user_id")
    share_link.save!

    redirect_to share_links_path, notice: "Share link created."
  end

  def bulk_create
    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?)
    if folder_ids.empty?
      redirect_to dashboard_path, alert: "Select at least one folder to share."
      return
    end

    folders = current_user.folders.where(id: folder_ids)

    share_link = ShareLink.new(expires_at: nil)
    share_link.user_id = current_user.id if ShareLink.column_names.include?("user_id")
    share_link.save!

    folders.each do |f|
      ShareLinkFolder.find_or_create_by!(share_link: share_link, folder: f)
    end

    redirect_to share_links_path, notice: "Share link created."
  end

  def bulk_create_files
    cv_ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)
    if cv_ids.empty?
      redirect_back fallback_location: dashboard_path, alert: "Select at least one file to share."
      return
    end

    expires_at =
      if params[:expires_at].present?
        Time.zone.parse(params[:expires_at])
      else
        nil
      end

    cvs = Cv.joins(:folder).where(id: cv_ids, folders: { user_id: current_user.id }).with_attached_file

    share_link = ShareLink.new(expires_at: expires_at)
    share_link.user_id = current_user.id if ShareLink.column_names.include?("user_id")
    share_link.save!

    cvs.each do |cv|
      ShareLinkCv.find_or_create_by!(share_link: share_link, cv: cv)
    end

    redirect_to share_links_path, notice: "Share link created."
  end

  def destroy
    share_link = ShareLink.find(params[:id])

    if (share_link.respond_to?(:user_id) && share_link.user_id == current_user.id) ||
       (share_link.folder && share_link.folder.user_id == current_user.id) ||
       (share_link.all_folders.any? { |f| f.user_id == current_user.id })
      share_link.destroy
      redirect_to share_links_path, notice: "Share link deleted."
    else
      redirect_to share_links_path, alert: "Not allowed."
    end
  end

  # ✅ password unlock (token-based)
  def unlock
    if @share_link.expired?
      render plain: "This share link has expired.", status: :gone
      return
    end

    if !@share_link.password_protected?
      redirect_to share_link_path(@share_link.token)
      return
    end

    pw = params[:password].to_s
    if @share_link.authenticate(pw)
      session[:unlocked_share_links] ||= {}
      session[:unlocked_share_links][@share_link.token] = true
      redirect_to share_link_path(@share_link.token), notice: "Unlocked."
    else
      flash.now[:alert] = "Wrong password."
      render :password, status: :unprocessable_entity
    end
  end

  # ✅ optional: owner can disable/enable (doesn’t affect existing features unless you add UI)
  def toggle_disabled
    share_link = ShareLink.find(params[:id])

    allowed =
      (share_link.respond_to?(:user_id) && share_link.user_id == current_user.id) ||
      (share_link.folder && share_link.folder.user_id == current_user.id) ||
      (share_link.all_folders.any? { |f| f.user_id == current_user.id })

    unless allowed
      redirect_to share_links_path, alert: "Not allowed."
      return
    end

    share_link.update!(disabled: !share_link.disabled?)
    redirect_to share_links_path, notice: (share_link.disabled? ? "Share link disabled." : "Share link enabled.")
  end

  # Public show (token)
  def show
    if @share_link.expired?
      render plain: "This share link has expired.", status: :gone
      return
    end

    # Files-only share
    if @share_link.cvs.any?
      @files_only = true
      @folders = []
      @folder = nil
      @subfolders = []
      @cvs = @share_link.cvs.with_attached_file.order(updated_at: :desc)
      return
    end

    # Folder share (roots)
    @files_only = false
    @folders = @share_link.all_folders

    # ✅ HARDEN: allow browsing ONLY inside shared roots descendants
    allowed_folder_ids = @folders.flat_map { |f| f.self_and_descendant_ids }.uniq

    if params[:folder_id].present?
      fid = params[:folder_id].to_i
      @folder = Folder.where(id: allowed_folder_ids).find_by(id: fid)
    else
      @folder = nil
    end

    @subfolders = @folder ? @folder.subfolders.where(id: allowed_folder_ids).order(updated_at: :desc) : []
    @cvs = @folder ? @folder.cvs.with_attached_file.order(updated_at: :desc) : []
  end

  # Public preview via token (permission-checked)
  def preview
    return head :forbidden unless @share_link.allow_preview?

    cv = find_shared_cv!(params[:cv_id])
    redirect_to rails_blob_path(cv.file, disposition: "inline")
  end

  # Public download via token (permission-checked)
  def download
    return head :forbidden unless @share_link.allow_download?

    cv = find_shared_cv!(params[:cv_id])
    redirect_to rails_blob_path(cv.file, disposition: "attachment")
  end

  private

  def set_share_link_by_token
    @share_link = ShareLink.includes(:cvs, :folders).find_by!(token: params[:id])
  end

  def enforce_require_login_if_needed!
    return unless @share_link.respond_to?(:require_login) && @share_link.require_login
    return if current_user
    redirect_to login_path, alert: "Please login to access this share link."
  end

  def enforce_not_disabled!
    return unless @share_link.respond_to?(:disabled) && @share_link.disabled?
    render plain: "This share link is disabled.", status: :gone
  end

  def enforce_password_if_needed!
    return unless @share_link.respond_to?(:password_digest) && @share_link.password_protected?
    session[:unlocked_share_links] ||= {}
    return if session[:unlocked_share_links][@share_link.token]

    render :password, status: :unauthorized
  end

  # CV must be part of this share:
  # - direct file share OR
  # - inside ANY folder within shared roots descendant tree
  def find_shared_cv!(cv_id)
    cv_id = cv_id.to_i

    if @share_link.cvs.exists?(id: cv_id)
      cv = @share_link.cvs.with_attached_file.find(cv_id)
      raise ActiveRecord::RecordNotFound unless cv.file.attached?
      return cv
    end

    roots = @share_link.all_folders
    allowed_folder_ids = roots.flat_map { |f| f.self_and_descendant_ids }.uniq

    cv = Cv.joins(:folder).with_attached_file.where(id: cv_id, folders: { id: allowed_folder_ids }).first
    raise ActiveRecord::RecordNotFound unless cv&.file&.attached?
    cv
  end
end
