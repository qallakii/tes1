class RatingsController < ApplicationController
  before_action :require_login
  before_action :set_rating, only: [:edit, :update, :destroy]

  def index
    @ratings = Rating.order(created_at: :desc).page(params[:page]).per(10)
  end


    # Filter by stars
    if params[:stars].present?
      @ratings = @ratings.where(stars: params[:stars])
    end

    # Sort ratings
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
  end

  def create
    @cv = Cv.find(params[:cv_id])
    @rating = @cv.ratings.new(stars: params[:stars], comment: params[:comment], user: current_user)

    if @rating.save
      redirect_back fallback_location: folder_path(@cv.folder), notice: "Rating submitted!"
    else
      redirect_back fallback_location: folder_path(@cv.folder), alert: @rating.errors.full_messages.join(", ")
    end
  end

  def edit; end

  def update
    if @rating.update(rating_params)
      redirect_to ratings_path, notice: "Rating updated!"
    else
      render :edit
    end
  end

  def destroy
    @rating.destroy
    redirect_to ratings_path, notice: "Rating deleted!"
  end

  private

  def set_rating
    @rating = Rating.find(params[:id])
  end

  def rating_params
    params.require(:rating).permit(:stars, :comment)
  end
end
