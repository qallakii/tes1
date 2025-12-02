class ApplicationController < ActionController::Base
  # Make Devise helpers available in all views
  helper_method :current_user, :user_signed_in?
end
