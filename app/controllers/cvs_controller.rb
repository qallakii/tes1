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
      flash[:notice] = "CV uploaded successfully."
      redirect_to folder_path(@folder)
    else
      flash.now[:alert] = @cv.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
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

  # ✅ NEW: delete multiple selected files
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

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def cv_params
    params.require(:cv).permit(:file, :title)
  end
end
