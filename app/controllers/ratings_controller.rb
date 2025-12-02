class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rating, only: [:edit, :update, :destroy]

  # List all ratings
  def index
    @ratings = Rating.all
  end

  # Create a new rating for a CV
  def create
    @cv = Cv.find(params[:cv_id])
    @rating = @cv.ratings.new(stars: params[:stars], comment: params[:comment], user: current_user)

    if @rating.save
      redirect_back fallback_location: folder_path(@cv.folder), notice: "Rating submitted!"
    else
      redirect_back fallback_location: folder_path(@cv.folder), alert: @rating.errors.full_messages.join(", ")
    end
  end

  # Optional: edit/update/destroy actions
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
