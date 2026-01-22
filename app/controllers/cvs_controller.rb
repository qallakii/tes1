class CvsController < ApplicationController
  before_action :require_login
  before_action :set_folder

  def index
    @cvs = @folder.cvs.order(created_at: :desc)
  end

  def new
    @cv = @folder.cvs.new
  end

  # ✅ Updated: supports single + multiple files
  def create
    files = Array(params.dig(:cv, :files)).compact
    paths = Array(params.dig(:cv, :paths))

    if files.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "No files selected."
      return
    end

    created = 0
    skipped = 0

    files.each_with_index do |uploaded, idx|
      rel = paths[idx].to_s
      parts = rel.split("/").reject(&:blank?)

      dir_parts =
        if parts.length >= 2
          parts[1..-2] || []
        else
          []
        end

      target_folder = @folder

      dir_parts.each do |name|
        target_folder = current_user.folders.find_or_create_by!(parent_id: target_folder.id, name: name)
      end

      cv = current_user.cvs.new(folder_id: target_folder.id)
      cv.file.attach(uploaded)
      cv.title = uploaded.original_filename.to_s.sub(/\.[^.]+\z/, "") # ✅ safe default title

      if cv.save
        created += 1
      else
        skipped += 1
      end
    end

    notice = "Uploaded #{created} file(s)."
    notice += " Skipped #{skipped} (not PDF / too big / invalid)." if skipped > 0

    redirect_to folder_path(@folder), notice: notice
  end



  def show
    @cv = @folder.cvs.find(params[:id])
  end

  def update
    @cv = @folder.cvs.find(params[:id])

    if @cv.update(cv_params.slice(:title))
      flash[:notice] = "File renamed."
    else
      flash[:alert] = @cv.errors.full_messages.join(", ")
    end

    redirect_to folder_path(@folder)
  end

  def destroy
    @cv = @folder.cvs.find(params[:id])
    @cv.destroy
    flash[:notice] = "File deleted."
    redirect_to folder_path(@folder)
  end

  def bulk_destroy
    ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)
    if ids.any?
      @folder.cvs.where(id: ids).destroy_all
      flash[:notice] = "Selected files deleted."
    else
      flash[:alert] = "No files selected."
    end
    redirect_to folder_path(@folder)
  end

  # If you already implemented bulk_move elsewhere, keep it.
  # If not, leave the route but don’t show the button yet.
  def bulk_move
    ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)
    target_folder_id = params[:target_folder_id].presence

    if ids.empty?
      return redirect_to folder_path(@folder), alert: "No files selected."
    end

    unless target_folder_id
      return redirect_to folder_path(@folder), alert: "Please choose a destination folder."
    end

    target = current_user.folders.find_by(id: target_folder_id)
    return redirect_to folder_path(@folder), alert: "Destination folder not found." unless target

    moved = @folder.cvs.where(id: ids).update_all(folder_id: target.id)
    redirect_to folder_path(@folder), notice: "#{moved} file#{moved == 1 ? '' : 's'} moved."
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def cv_params
    # keep both :file (single) and :files (multiple)
    params.require(:cv).permit(:file, :title, files: [])
  end
end
