# app/controllers/folders_controller.rb
require "zip"

class FoldersController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: %i[
    show destroy update rename bulk_move_items bulk_destroy_items bulk_download_items download
  ]

  def index
    @folders = current_user.folders.where(parent_id: nil).order(updated_at: :desc)
  end

  def show
    @subfolders = @folder.subfolders.order(updated_at: :desc)
    @cvs = @folder.cvs.includes(file_attachment: :blob).order(updated_at: :desc)

    @all_folders_for_tree = current_user.folders.order(:name)
  end

  def new
    @folder = current_user.folders.new(parent_id: params[:parent_id])
  end

  def create
    @folder = current_user.folders.new(folder_params)

    if @folder.save
      redirect_to(@folder.parent_id.present? ? folder_path(@folder.parent_id) : folders_path,
                  notice: "Folder created successfully")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @folder.update(folder_params.slice(:name))
      redirect_back fallback_location: folder_path(@folder), notice: "Folder renamed."
    else
      redirect_back fallback_location: folder_path(@folder), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def rename
    if @folder.update(params.require(:folder).permit(:name))
      redirect_back fallback_location: folder_path(@folder), notice: "Folder renamed."
    else
      redirect_back fallback_location: folder_path(@folder), alert: @folder.errors.full_messages.to_sentence
    end
  end

  # ✅ Moves BOTH folders and files + avoids "fake moved" when nothing changed
  def bulk_move_items
    target_id = params[:target_folder_id].to_s
    if target_id.blank?
      redirect_back fallback_location: folder_path(@folder), alert: "Choose a destination folder."
      return
    end

    if target_id == @folder.id.to_s
      redirect_back fallback_location: folder_path(@folder), alert: "You’re already in this folder. Pick a different destination."
      return
    end

    target_folder = current_user.folders.find(target_id)

    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?)
    cv_ids     = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)

    moved_folders = 0
    moved_files   = 0

    if folder_ids.any?
      if folder_ids.include?(target_folder.id.to_s)
        redirect_back fallback_location: folder_path(@folder), alert: "You can’t move a folder into itself."
        return
      end

      moved_folders = current_user.folders
        .where(id: folder_ids)
        .where.not(parent_id: target_folder.id)
        .update_all(parent_id: target_folder.id, updated_at: Time.current)
    end

    if cv_ids.any?
      moved_files = current_user.cvs
        .where(id: cv_ids)
        .where.not(folder_id: target_folder.id)
        .update_all(folder_id: target_folder.id, updated_at: Time.current)
    end

    if moved_folders.zero? && moved_files.zero?
      redirect_back fallback_location: folder_path(@folder), alert: "Nothing moved (items are already in that folder)."
    else
      redirect_to folder_path(@folder), notice: "Moved #{moved_folders} folder(s) and #{moved_files} file(s)."
    end
  end

  # ✅ NEW: Safe recursive delete for selected folders + files (and clears share references)
  def bulk_destroy_items
    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?)
    cv_ids     = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)

    if folder_ids.empty? && cv_ids.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "No items selected."
      return
    end

    # Only allow deleting user's folders
    root_folders = current_user.folders.where(id: folder_ids)
    root_folder_ids = root_folders.pluck(:id)

    # Expand roots -> include all descendants
    all_folder_ids = root_folders.flat_map(&:self_and_descendant_ids).uniq

    # Files from selected folders (recursive) + explicitly selected files
    from_folders_cv_ids = current_user.cvs.where(folder_id: all_folder_ids).pluck(:id)
    direct_cv_ids       = current_user.cvs.where(id: cv_ids).pluck(:id)

    all_cv_ids = (from_folders_cv_ids + direct_cv_ids).uniq

    # ✅ IMPORTANT: clear ShareLink join rows + direct folder share references FIRST (prevents FK errors)
    ShareLinkFolder.where(folder_id: all_folder_ids).delete_all
    ShareLinkCv.where(cv_id: all_cv_ids).delete_all
    ShareLink.where(folder_id: all_folder_ids).delete_all

    deleted_files = 0
    deleted_folders = 0

    if all_cv_ids.any?
      deleted_files = current_user.cvs.where(id: all_cv_ids).destroy_all.size
    end

    # Destroy only roots; dependent: :destroy handles descendants
    if root_folder_ids.any?
      deleted_folders = current_user.folders.where(id: root_folder_ids).destroy_all.size
    end

    if deleted_files.zero? && deleted_folders.zero?
      redirect_back fallback_location: folder_path(@folder), alert: "Nothing deleted."
    else
      redirect_back fallback_location: folder_path(@folder),
                    notice: "Deleted #{deleted_folders} folder(s) and #{deleted_files} file(s)."
    end
  end

  # ✅ NEW: Download ONE folder recursively as zip
  def download
    zip_data = build_zip_for_folders([@folder.id])

    filename = "#{safe_name(@folder.name)}.zip"
    send_data zip_data,
              type: "application/zip",
              filename: filename,
              disposition: "attachment"
  end

  # ✅ NEW: Bulk download selected folders (recursive) + optional selected files as zip
  # POST /folders/:id/bulk_download_items
  def bulk_download_items
    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?)
    cv_ids     = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)

    # Only user's folders/files
    folder_ids = current_user.folders.where(id: folder_ids).pluck(:id)
    cv_ids     = current_user.cvs.where(id: cv_ids).pluck(:id)

    if folder_ids.empty? && cv_ids.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "Select at least one folder or file to download."
      return
    end

    zip_data = build_zip_for_folders(folder_ids, extra_cv_ids: cv_ids)

    filename = "download_#{Time.current.strftime("%Y%m%d_%H%M%S")}.zip"
    send_data zip_data,
              type: "application/zip",
              filename: filename,
              disposition: "attachment"
  end

  def destroy
    parent_id = @folder.parent_id

    # Clear share references before destroy (extra safety)
    ShareLinkFolder.where(folder_id: @folder.self_and_descendant_ids).delete_all
    ShareLink.where(folder_id: @folder.self_and_descendant_ids).delete_all

    @folder.destroy

    redirect_to(parent_id.present? ? folder_path(parent_id) : folders_path, notice: "Folder deleted")
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  def safe_name(name)
    name.to_s.strip.gsub(/[^\w\- ]+/, "").gsub(/\s+/, "_").presence || "folder"
  end

  def build_zip_for_folders(folder_ids, extra_cv_ids: [])
    roots = current_user.folders.where(id: folder_ids).includes(:subfolders, :cvs)

    Zip::OutputStream.write_buffer do |zip|
      added_dirs = {}

      add_dir = lambda do |dir_path|
        dir_path = dir_path.to_s
        dir_path = "#{dir_path}/" unless dir_path.end_with?("/")
        return if dir_path == "/"
        return if added_dirs[dir_path]

        zip.put_next_entry(dir_path)
        added_dirs[dir_path] = true
      end

      add_folder_recursive = lambda do |folder, base_path|
        folder_path = File.join(base_path, safe_name(folder.name))
        add_dir.call(folder_path)

        folder.cvs.includes(file_attachment: :blob).find_each do |cv|
          next unless cv.file.attached?
          entry_path = File.join(folder_path, cv.file.filename.to_s)
          zip.put_next_entry(entry_path)
          zip.write(cv.file.download)
        end

        folder.subfolders.order(:name).each do |child|
          add_folder_recursive.call(child, folder_path)
        end
      end

      roots.order(:name).each do |root|
        add_folder_recursive.call(root, "")
      end

      # Extra selected files (not necessarily inside selected folders)
      extras = current_user.cvs.where(id: extra_cv_ids).includes(file_attachment: :blob)
      if extras.any?
        add_dir.call("Selected_Files")
        extras.each do |cv|
          next unless cv.file.attached?
          entry_path = File.join("Selected_Files", cv.file.filename.to_s)
          zip.put_next_entry(entry_path)
          zip.write(cv.file.download)
        end
      end
    end.string
  end
end
