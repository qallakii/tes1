class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder, only: %i[show destroy]

  def index
    @folders = current_user.folders
  end

  def show
    @cvs = @folder.cvs.page(params[:page]).per(10)
  end

  def new
    @folder = current_user.folders.new
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
      redirect_to folders_path, notice: "Folder created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @folder.destroy
    redirect_to folders_path, notice: "Folder deleted"
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name)
  end
end
