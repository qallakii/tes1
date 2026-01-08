class CvsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder

  def new
    @cv = @folder.cvs.new
  end

  def create
    @cv = @folder.cvs.new(cv_params)
    if @cv.save
      redirect_to folder_path(@folder), notice: "CV uploaded successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cv = @folder.cvs.find(params[:id])
    cv.destroy
    redirect_to folder_path(@folder), notice: "CV deleted"
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def cv_params
    params.require(:cv).permit(:title, :description, :file)
  end
end
