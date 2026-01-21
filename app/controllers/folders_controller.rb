class FoldersController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: %i[show destroy update]

  def index
    @folders = current_user.folders.where(parent_id: nil).order(updated_at: :desc)
  end

  def show
    @subfolders = @folder.subfolders.order(updated_at: :desc)
    @cvs = @folder.cvs.includes(file_attachment: :blob).order(updated_at: :desc)

    # ✅ used by the Move modal tree
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
    folder = current_user.folders.find(params[:id])

    if folder.update(params.require(:folder).permit(:name))
      redirect_back fallback_location: folder_path(folder), notice: "Folder renamed."
    else
      redirect_back fallback_location: folder_path(folder), alert: folder.errors.full_messages.to_sentence
    end
  end

  # ✅ NEW: move mixed selection (folders + files) to a target folder
  def bulk_move_items
    target_id = params[:target_folder_id].presence
    return redirect_back(fallback_location: dashboard_path, alert: "Choose a destination folder.") unless target_id

    target = current_user.folders.find_by(id: target_id)
    return redirect_back(fallback_location: dashboard_path, alert: "Destination folder not found.") unless target

    folder_ids = Array(params[:folder_ids]).map(&:to_s).reject(&:blank?).map(&:to_i)
    cv_ids     = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?).map(&:to_i)

    if folder_ids.empty? && cv_ids.empty?
      return redirect_back(fallback_location: folder_path(params[:id]), alert: "Nothing selected to move.")
    end

    moved_folders = 0
    moved_files = 0
    errors = []

    # ---- move folders (parent_id) ----
    folders = current_user.folders.where(id: folder_ids)

    folders.find_each do |f|
      # Prevent moving a folder into itself or into its own descendants
      target_ancestor_ids =
        begin
          target.ancestors.map(&:id)
        rescue
          []
        end

      if target.id == f.id || target_ancestor_ids.include?(f.id)
        errors << "Can't move '#{f.name}' into itself / its subfolder."
        next
      end

      if f.update(parent_id: target.id)
        moved_folders += 1
      else
        errors << "Failed to move folder '#{f.name}'."
      end
    end

    # ---- move files (folder_id) ----
    if cv_ids.any?
      cvs = Cv.where(id: cv_ids, user_id: current_user.id)
      moved_files = cvs.update_all(folder_id: target.id)
    end

    if errors.any?
      notice = []
      notice << "#{moved_folders} folder#{moved_folders == 1 ? '' : 's'} moved" if moved_folders > 0
      notice << "#{moved_files} file#{moved_files == 1 ? '' : 's'} moved" if moved_files > 0
      msg = (notice.join(", ").presence || "Move finished with errors.") + ". " + errors.join(" | ")
      redirect_back fallback_location: folder_path(params[:id]), alert: msg
    else
      msg = []
      msg << "#{moved_folders} folder#{moved_folders == 1 ? '' : 's'} moved" if moved_folders > 0
      msg << "#{moved_files} file#{moved_files == 1 ? '' : 's'} moved" if moved_files > 0
      redirect_back fallback_location: folder_path(params[:id]), notice: msg.join(", ")
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
