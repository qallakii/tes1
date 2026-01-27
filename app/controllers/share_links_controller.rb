# app/controllers/share_links_controller.rb
class ShareLinksController < ApplicationController
  before_action :require_login, except: [:show, :preview, :download]
  before_action :set_share_link_by_token, only: [:show, :preview, :download]
  before_action :enforce_require_login_if_needed!, only: [:show, :preview, :download]

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

    expires_at =
      if params[:expires_at].present?
        Time.zone.parse(params[:expires_at])
      else
        nil
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

    # Folder share
    @files_only = false
    @folders = @share_link.all_folders

    # HARDEN: only allow folder_id that is part of this share
    if params[:folder_id].present?
      allowed_ids = @folders.map(&:id)
      fid = params[:folder_id].to_i
      @folder = allowed_ids.include?(fid) ? @folders.find { |f| f.id == fid } : nil
    else
      @folder = nil
    end

    @subfolders = @folder ? @folder.subfolders.order(updated_at: :desc) : []
    @cvs = @folder ? @folder.cvs.with_attached_file.order(updated_at: :desc) : []
  end

  # Public preview via token (permission-checked)
  def preview
    return head :forbidden unless @share_link.allow_preview?

    cv = find_shared_cv!(params[:cv_id])
    redirect_to rails_blob_url(cv.file, disposition: "inline")
  end

  # Public download via token (permission-checked)
  def download
    return head :forbidden unless @share_link.allow_download?

    cv = find_shared_cv!(params[:cv_id])
    redirect_to rails_blob_url(cv.file, disposition: "attachment")
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

  # CV must be part of this share (direct file share OR inside shared folder)
  def find_shared_cv!(cv_id)
    cv_id = cv_id.to_i

    # Direct file share
    if @share_link.cvs.exists?(id: cv_id)
      cv = @share_link.cvs.with_attached_file.find(cv_id)
      raise ActiveRecord::RecordNotFound unless cv.file.attached?
      return cv
    end

    # Folder share
    folder_ids = @share_link.all_folders.map(&:id)
    cv = Cv.joins(:folder).with_attached_file.where(id: cv_id, folders: { id: folder_ids }).first
    raise ActiveRecord::RecordNotFound unless cv&.file&.attached?
    cv
  end
end
