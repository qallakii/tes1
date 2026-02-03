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
    files = Array(params.dig(:cv, :files)).compact
    paths = Array(params.dig(:cv, :paths))

    if files.empty?
      redirect_back fallback_location: folder_path(@folder), alert: "No files selected."
      return
    end

    created = 0

    files.each_with_index do |uploaded, idx|
      rel = paths[idx].to_s
      parts = rel.split("/").reject(&:blank?)

      dir_parts =
        if parts.length >= 2
          parts[1..-2] || []
        else
          []
        end

      target_folder = @folder

      dir_parts.each do |name|
        # Always create ONLY under current user's tree
        target_folder = current_user.folders.find_or_create_by!(parent_id: target_folder.id, name: name)
      end

      cv = current_user.cvs.new(folder_id: target_folder.id)
      cv.file.attach(uploaded)

      created += 1 if cv.save
    end

    redirect_to folder_path(@folder), notice: "Uploaded #{created} file(s)."
  end

  def show
    @cv = current_user.cvs.joins(:folder).where(folders: { id: @folder.id }).find(params[:id])
  end

  def update
    @cv = current_user.cvs.joins(:folder).where(folders: { id: @folder.id }).find(params[:id])

    if @cv.update(cv_params.slice(:title))
      flash[:notice] = "File renamed."
    else
      flash[:alert] = @cv.errors.full_messages.join(", ")
    end

    redirect_to folder_path(@folder)
  end

  def destroy
    @cv = current_user.cvs.joins(:folder).where(folders: { id: @folder.id }).find(params[:id])
    @cv.destroy
    redirect_to folder_path(@folder), notice: "File deleted."
  end

  def bulk_destroy
    ids = Array(params[:cv_ids]).map(&:to_s).reject(&:blank?)

    if ids.any?
      current_user.cvs.where(id: ids, folder_id: @folder.id).destroy_all
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
    params.require(:cv).permit(:file, :title, files: [])
  end

  def download
    cv = current_user.cvs.find(params[:id])
    redirect_to rails_blob_path(cv.file, disposition: "attachment")
  end

end
