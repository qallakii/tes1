class CvsController < ApplicationController
  before_action :authenticate_user!

  def index
    @cvs = Cv.all
  end
end
