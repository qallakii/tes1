class CvsController < ApplicationController
  before_action :require_login
  before_action :set_folder

  def index
    @cvs = @folder.cvs.order(created_at: :desc)
  end

  def new
    @cv = @folder.cvs.new
  end

  def create
    @cv = @folder.cvs.new(cv_params)
    @cv.user = current_user

    if @cv.save
      flash[:notice] = "File uploaded successfully."
      redirect_to folder_path(@folder)
    else
      redirect_to folder_path(@folder), alert: @cv.errors.full_messages.to_sentence
    end
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

  # ✅ delete multiple selected files
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

  # ✅ move selected files to another folder (same user)
  def bulk_move
    ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)
    target_folder_id = params[:target_folder_id].presence

    return redirect_to(folder_path(@folder), alert: "No files selected.") if ids.empty?
    return redirect_to(folder_path(@folder), alert: "Choose a destination folder.") if target_folder_id.blank?

    target_folder = current_user.folders.find(target_folder_id)

    moved = @folder.cvs.where(id: ids).update_all(folder_id: target_folder.id)
    flash[:notice] = "Moved #{moved} file(s)."
    redirect_to folder_path(target_folder)
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def cv_params
    params.require(:cv).permit(:file, :title)
  end
end
