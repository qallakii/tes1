class FoldersController < ApplicationController
  before_action :require_login

  def index
    @folders = current_user.folders.order(created_at: :desc)
  end

  def show
    @folder = current_user.folders.find(params[:id])
    @cvs = @folder.cvs.order(created_at: :desc)
  end

  def new
    @folder = Folder.new
  end

  def create
    @folder = current_user.folders.build(folder_params)
    if @folder.save
      flash[:notice] = "Folder created successfully."
      redirect_to folders_path
    else
      flash.now[:alert] = @folder.errors.full_messages.join(", ")
      render :new
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end
end
