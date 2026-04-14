class RatingsController < ApplicationController
  before_action :require_login
  before_action :set_rating, only: [:edit, :update, :destroy]
  before_action :set_cv, only: [:create]

  def index
    @ratings = rating_scope.includes(:cv, :user)
    if params[:stars].present?
      @ratings = @ratings.where(stars: params[:stars])
    end

    case params[:sort]
    when "newest"
      @ratings = @ratings.order(created_at: :desc)
    when "oldest"
      @ratings = @ratings.order(created_at: :asc)
    when "highest"
      @ratings = @ratings.order(stars: :desc)
    when "lowest"
      @ratings = @ratings.order(stars: :asc)
    else
      @ratings = @ratings.order(created_at: :desc)
    end

    @ratings = @ratings.page(params[:page]).per(10)
  end

  def create
    @rating = @cv.ratings.find_or_initialize_by(user: current_user)
    @rating.assign_attributes(rating_params)

    if @rating.save
      redirect_to folder_cv_path(@folder, @cv), notice: "Rating submitted!"
    else
      redirect_to folder_cv_path(@folder, @cv), alert: @rating.errors.full_messages.join(", ")
    end
  end

  def edit; end

  def update
    if @rating.update(rating_params)
      redirect_to ratings_path, notice: "Rating updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rating.destroy
    redirect_to ratings_path, notice: "Rating deleted!"
  end

  private

  def set_cv
    @folder = current_user.folders.find(params[:folder_id])
    @cv = @folder.cvs.find(params[:cv_id])
  end

  def set_rating
    @rating = rating_scope.find(params[:id])
  end

  def rating_scope
    current_user.admin? ? Rating.all : current_user.ratings
  end

  def rating_params
    params.require(:rating).permit(:stars, :comment)
  end
end
