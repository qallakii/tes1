class FoldersController < ApplicationController
  before_action :require_login
  before_action :set_folder, only: %i[show destroy]

  def index
    @folders = current_user.folders.where(parent_id: nil).order(updated_at: :desc)
  end

  def show
    @folder = current_user.folders.find(params[:id])

    @subfolders = @folder.subfolders.order(updated_at: :desc)
    @cvs = @folder.cvs.includes(file_attachment: :blob).order(updated_at: :desc)

    # ✅ one combined list like Google Drive
    @items = (@subfolders.to_a + @cvs.to_a).sort_by do |item|
      type_rank = item.is_a?(Folder) ? 0 : 1
      name =
        if item.is_a?(Folder)
          item.name.to_s.downcase
        else
          (item.title.presence || item.file.filename.to_s).downcase
        end
      [type_rank, name]
    end
  end

  def new
    # parent_id passed from link: new_folder_path(parent_id: @folder.id)
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
