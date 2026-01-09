class CvsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder

  def new
    @cv = @folder.cvs.new
  end

  def create
    @cv = @folder.cvs.new(cv_params)
    @cv.user_id = current_user.id if @cv.respond_to?(:user_id=)

    if @cv.save
      redirect_to folder_path(@folder), notice: "CV uploaded successfully"
    else
      redirect_to folder_path(@folder), alert: @cv.errors.full_messages.to_sentence
    end
  end

  def update
    cv = @folder.cvs.find(params[:id])
    if cv.update(update_params)
      redirect_to folder_path(@folder), notice: "CV renamed"
    else
      redirect_to folder_path(@folder), alert: cv.errors.full_messages.to_sentence
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

  def update_params
    params.require(:cv).permit(:title)
  end
end
