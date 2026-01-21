class FoldersController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: %i[show destroy update rename bulk_move_items]

  def index
    @folders = current_user.folders.where(parent_id: nil).order(updated_at: :desc)
  end

  def show
    @subfolders = @folder.subfolders.order(updated_at: :desc)
    @cvs = @folder.cvs.includes(file_attachment: :blob).order(updated_at: :desc)

    # if your move tree uses this, keep it:
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

    # If trying to move into the SAME folder → no-op
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

  def destroy
    parent_id = @folder.parent_id
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
end
