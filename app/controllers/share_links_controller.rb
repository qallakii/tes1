class ShareLinksController < ApplicationController
  before_action :require_login, except: :show

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

  # ✅ Single folder share (now shares the whole subtree)
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

    # ✅ Attach folder + all subfolders
    attach_subtree_folders!(share_link, [folder.id])

    redirect_to share_links_path, notice: "Share link created."
  end

  # ✅ ONE link -> MANY folders (now shares each selected folder subtree)
  def bulk_create
    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?)
    if folder_ids.empty?
      redirect_to dashboard_path, alert: "Select at least one folder to share."
      return
    end

    share_link = ShareLink.new(expires_at: nil)
    share_link.user_id = current_user.id if ShareLink.column_names.include?("user_id")
    share_link.save!

    attach_subtree_folders!(share_link, folder_ids)

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

  def show
    @share_link = ShareLink
      .includes(:cvs, :folders, :folder)
      .find_by!(token: params[:id])

    if @share_link.expired?
      render plain: "This share link has expired.", status: :gone
      return
    end

    # ✅ FILE-ONLY SHARE
    if @share_link.cvs.any?
      @files_only = true
      @folders = []
      @folder = nil
      @cvs = @share_link.cvs.with_attached_file.order(updated_at: :desc)
      return
    end

    # ✅ FOLDER SHARE (single or many) — recursive + hardened
    @files_only = false

    roots = @share_link.all_folders
    @folders = roots

    allowed_ids = roots.flat_map(&:self_and_descendant_ids).uniq

    if params[:folder_id].present?
      @folder = Folder.where(id: allowed_ids).find_by(id: params[:folder_id])
      unless @folder
        render plain: "Not found", status: :not_found
        return
      end
    else
      @folder = nil
    end

    if @folder
      @subfolders = @folder.subfolders.where(id: allowed_ids).order(updated_at: :desc)
      @cvs = @folder.cvs.with_attached_file.order(updated_at: :desc)
    else
      @subfolders = []
      @cvs = []
    end
  end


  private

  # ✅ Add folder + all descendants to share_link_folders
  def attach_subtree_folders!(share_link, folder_ids)
    folder_ids = Array(folder_ids).map(&:to_s).reject(&:blank?)
    return if folder_ids.empty?

    roots = current_user.folders.where(id: folder_ids)

    all_ids = []

    roots.each do |root|
      if root.respond_to?(:subtree_ids)
        # ancestry gem: includes self + all descendants
        all_ids.concat(root.subtree_ids)
      else
        # fallback recursion if you don’t use ancestry
        all_ids.concat(recursive_desc_ids(root))
      end
    end

    all_ids = all_ids.uniq

    all_ids.each do |fid|
      ShareLinkFolder.find_or_create_by!(share_link_id: share_link.id, folder_id: fid)
    end
  end

  # Fallback only (if no ancestry)
  def recursive_desc_ids(folder)
    ids = [folder.id]
    current_user.folders.where(parent_id: folder.id).find_each do |child|
      ids.concat(recursive_desc_ids(child))
    end
    ids
  end
end
