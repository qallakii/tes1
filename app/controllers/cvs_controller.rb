def show
  @cv = Cv.find(params[:id])
  @ratings = @cv.ratings.includes(:user)
  @rating = Rating.new
end
