class FoldersController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: %i[show destroy rename]

  def index
    @folders = current_user.folders.where(parent_id: nil).order(updated_at: :desc)
  end

  def show
    @subfolders = @folder.subfolders.order(updated_at: :desc)
    @cvs = @folder.cvs.includes(file_attachment: :blob).order(updated_at: :desc)

    # ✅ used for Move Tree modal
    @all_folders_for_tree = current_user.folders.select(:id, :name, :parent_id).order(:name)
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

  # ✅ rename from kebab menu (modal)
  def rename
    if @folder.update(params.require(:folder).permit(:name))
      redirect_back fallback_location: folder_path(@folder), notice: "Folder renamed."
    else
      redirect_back fallback_location: folder_path(@folder), alert: @folder.errors.full_messages.to_sentence
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
