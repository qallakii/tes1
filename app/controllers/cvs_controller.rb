class CvsController < ApplicationController
  before_action :require_login
  before_action :set_folder

  def index
    @cvs = @folder.cvs.order(created_at: :desc)
  end

  def new
    @cv = @folder.cvs.build
  end

  def create
    @cv = @folder.cvs.build(cv_params)
    @cv.user = current_user
    if @cv.save
      flash[:notice] = "CV uploaded successfully."
      redirect_to folder_path(@folder)
    else
      flash.now[:alert] = @cv.errors.full_messages.join(", ")
      render :new
    end
  end

  def show
    @cv = @folder.cvs.find(params[:id])
  end

  def destroy
    @cv = @folder.cvs.find(params[:id])
    @cv.destroy
    flash[:notice] = "CV deleted successfully."
    redirect_to folder_path(@folder)
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def cv_params
    params.require(:cv).permit(:title, :file)
  end
end
