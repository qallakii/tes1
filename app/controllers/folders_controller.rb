# app/controllers/folders_controller.rb
require "zip"
require "tempfile"

class FoldersController < ApplicationController
 # after_action :cleanup_temp_zips, only: %i[download bulk_download bulk_download_items]
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

    if @folder.parent_id.present? && !current_user.folders.exists?(id: @folder.parent_id)
      @folder.parent_id = nil
    end

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

  # ✅ Moves BOTH folders and files (HARDENED)
  def bulk_move_items
    target_id = params[:target_folder_id].to_s
    if target_id.blank?
      redirect_back fallback_location: folder_path(@folder), alert: "Choose a destination folder."
      return
    end

    target_folder = current_user.folders.find_by(id: target_id)
    unless target_folder
      redirect_back fallback_location: folder_path(@folder), alert: "Destination folder not found."
      return
    end

    if target_folder.id.to_s == @folder.id.to_s
      redirect_back fallback_location: folder_path(@folder), alert: "You’re already in this folder. Pick a different destination."
      return
    end

    # Only allow moving items that are actually listed inside THIS folder view:
    folder_ids = scoped_subfolder_ids(Array(params[:folder_ids]))
    cv_ids     = scoped_file_ids(Array(params[:cv_ids]))

    if folder_ids.empty? && cv_ids.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "No items selected."
      return
    end

    # Prevent cycles: cannot move a folder into itself OR its descendant
    moving_folders = current_user.folders.where(id: folder_ids)
    forbidden_target_ids = moving_folders.flat_map(&:self_and_descendant_ids).uniq
    if forbidden_target_ids.map(&:to_s).include?(target_folder.id.to_s)
      redirect_back fallback_location: folder_path(@folder), alert: "You can’t move a folder into itself (or into its own subfolder)."
      return
    end

    moved_folders = 0
    moved_files   = 0

    if folder_ids.any?
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

  # ✅ Safe recursive delete (HARDENED)
  def bulk_destroy_items
    folder_ids = scoped_subfolder_ids(Array(params[:folder_ids]))
    cv_ids     = scoped_file_ids(Array(params[:cv_ids]))

    if folder_ids.empty? && cv_ids.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "No items selected."
      return
    end

    root_folders = current_user.folders.where(id: folder_ids)

    # Expand roots -> include all descendants
    all_folder_ids = root_folders.flat_map(&:self_and_descendant_ids).uniq

    # Files from selected folders (recursive) + explicitly selected files (in this folder)
    from_folders_cv_ids = current_user.cvs.where(folder_id: all_folder_ids).pluck(:id)
    direct_cv_ids       = current_user.cvs.where(id: cv_ids).pluck(:id)
    all_cv_ids          = (from_folders_cv_ids + direct_cv_ids).uniq

    # Clear share references first (avoid FK errors)
    ShareLinkFolder.where(folder_id: all_folder_ids).delete_all
    ShareLinkCv.where(cv_id: all_cv_ids).delete_all
    ShareLink.where(folder_id: all_folder_ids).delete_all

    deleted_files = 0
    deleted_folders = 0

    deleted_files = current_user.cvs.where(id: all_cv_ids).destroy_all.size if all_cv_ids.any?

    # Destroy only roots; dependent: :destroy handles descendants
    deleted_folders = current_user.folders.where(id: root_folders.pluck(:id)).destroy_all.size if root_folders.any?

    redirect_back fallback_location: folder_path(@folder),
                  notice: "Deleted #{deleted_folders} folder(s) and #{deleted_files} file(s)."
  end

  # ✅ Download ONE folder recursively as zip (user-scoped)
  def download
    send_folder_zip(@folder)
  end

  # Dashboard/root bulk download (folders only)
  def bulk_download
    folder_ids = Array(params[:folder_ids]).map(&:to_i).uniq
    folders = current_user.folders.where(id: folder_ids)

    if folders.empty?
      redirect_back fallback_location: dashboard_path, alert: "No folders selected."
      return
    end

    tempfile = Tempfile.new(["folders-", ".zip"])
    tempfile.binmode

    Zip::File.open(tempfile.path, Zip::File::CREATE) do |zip|
      folders.find_each do |folder|
        add_folder_to_zip(zip, folder, "#{safe_zip_name(folder.name)}/")
      end
    end

    tempfile.close

    data = File.binread(tempfile.path)
    File.delete(tempfile.path) if File.exist?(tempfile.path)

    send_data data,
              filename: "folders-#{Time.zone.now.strftime('%Y%m%d-%H%M%S')}.zip",
              type: "application/zip",
              disposition: "attachment"
  end


  # ✅ Bulk download selected folders/files as zip (HARDENED + STREAMING)
  def bulk_download_items
    folder_ids = scoped_subfolder_ids(Array(params[:folder_ids]))
    cv_ids     = scoped_file_ids(Array(params[:cv_ids]))

    if folder_ids.empty? && cv_ids.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "Select at least one folder or file to download."
      return
    end

    folders = current_user.folders.where(id: folder_ids)
    cvs     = current_user.cvs.where(id: cv_ids).includes(file_attachment: :blob)

    # Nice UX: if only one file selected, download directly
    if folders.empty? && cvs.size == 1
      redirect_to rails_blob_path(cvs.first.file, disposition: "attachment")
      return
    end

    tempfile = Tempfile.new(["download-", ".zip"])
    tempfile.binmode

    Zip::File.open(tempfile.path, Zip::File::CREATE) do |zip|
      cvs.each do |cv|
        next unless cv.file.attached?

        entry_name = "Files/#{safe_zip_name(cv.file.filename.to_s)}"
        entry_name = uniquify_zip_entry(zip, entry_name)

        zip.get_output_stream(entry_name) do |out|
          cv.file.blob.open do |io|
            while (chunk = io.read(1024 * 1024))
              out.write(chunk)
            end
          end
        end
      end

      folders.find_each do |folder|
        add_folder_to_zip(zip, folder, "#{safe_zip_name(folder.name)}/")
      end
    end

    tempfile.close

    data = File.binread(tempfile.path)
    File.delete(tempfile.path) if File.exist?(tempfile.path)

    timestamp = Time.zone.now.strftime("%Y%m%d-%H%M%S")
    send_data data,
              filename: "download-#{timestamp}.zip",
              type: "application/zip",
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

  def remember_temp_zip(path)
    @temp_zip_paths ||= []
    @temp_zip_paths << path
  end

  def cleanup_temp_zips
    Array(@temp_zip_paths).each do |path|
      begin
        File.delete(path) if path.present? && File.exist?(path)
      rescue => e
        Rails.logger.warn("Temp zip cleanup failed for #{path}: #{e.class} #{e.message}")
      end
    end
  end


  def set_folder
    @folder = current_user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  # ✅ HARDENING: only allow acting on items visible inside THIS folder page
  def scoped_subfolder_ids(raw_ids)
    ids = Array(raw_ids).map(&:to_s).reject(&:blank?)
    return [] if ids.empty?
    current_user.folders.where(id: ids, parent_id: @folder.id).pluck(:id)
  end

  def scoped_file_ids(raw_ids)
    ids = Array(raw_ids).map(&:to_s).reject(&:blank?)
    return [] if ids.empty?
    current_user.cvs.where(id: ids, folder_id: @folder.id).pluck(:id)
  end

  def safe_name(name)
    name.to_s.strip.gsub(/[^\w\- ]+/, "").gsub(/\s+/, "_").presence || "folder"
  end

  # ✅ Send ONE folder zip using streaming writes (no RAM explosion)
  def send_folder_zip(folder)
    tempfile = Tempfile.new(["folder-", ".zip"])
    tempfile.binmode

    Zip::File.open(tempfile.path, Zip::File::CREATE) do |zip|
      add_folder_to_zip(zip, folder, "#{safe_zip_name(folder.name)}/")
    end

    tempfile.close

    data = File.binread(tempfile.path)
    File.delete(tempfile.path) if File.exist?(tempfile.path)

    timestamp = Time.zone.now.strftime("%Y%m%d-%H%M%S")
    send_data data,
              filename: "#{safe_zip_name(folder.name)}-#{timestamp}.zip",
              type: "application/zip",
              disposition: "attachment"

  end




  def safe_zip_name(name)
    # no UI changes; only avoids weird zip paths
    base = name.to_s.strip
    base = "folder" if base.empty?
    base.gsub(/[\/\\:\*\?"<>\|\x00-\x1F]/, "_")[0, 120]
  end

  def add_folder_to_zip(zip, folder, path_prefix)
    # Create folder entry (optional but helps some unzip tools)
    zip.mkdir(path_prefix) unless zip.find_entry(path_prefix)

    # Files in this folder
    folder.cvs.includes(file_attachment: :blob).find_each do |cv|
      next unless cv.file.attached?

      entry_name = "#{path_prefix}#{safe_zip_name(cv.file.filename.to_s)}"

      # Avoid duplicate names inside zip
      entry_name = uniquify_zip_entry(zip, entry_name)

      zip.get_output_stream(entry_name) do |out|
        cv.file.blob.open do |io|
          while (chunk = io.read(1024 * 1024)) # 1MB chunks
            out.write(chunk)
          end
        end
      end
    end

    # Recurse children
    folder.subfolders.find_each do |child|
      add_folder_to_zip(zip, child, "#{path_prefix}#{safe_zip_name(child.name)}/")
    end
  end

  def uniquify_zip_entry(zip, entry_name)
    return entry_name unless zip.find_entry(entry_name)

    ext  = File.extname(entry_name)
    base = entry_name.delete_suffix(ext)

    i = 2
    loop do
      candidate = "#{base} (#{i})#{ext}"
      return candidate unless zip.find_entry(candidate)
      i += 1
    end
  end
end
