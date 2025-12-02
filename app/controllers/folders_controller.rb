class FoldersController < ApplicationController
  before_action :authenticate_user!

  def index
    @folders = current_user.folders
  end

  def show
    @folder = current_user.folders.find(params[:id])
    @cvs = @folder.cvs
  end

  def new
    @folder = Folder.new
  end

  def create
    @folder = current_user.folders.build(folder_params)
    if @folder.save
      redirect_to @folder, notice: "Folder created!"
    else
      render :new, alert: "Error creating folder."
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end
end
