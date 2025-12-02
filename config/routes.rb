Rails.application.routes.draw do
  # Devise routes for users
  devise_for :users

  # Folders: all RESTful actions
  resources :folders

  # CVs: all RESTful actions
  resources :cvs

  # Share links: only index, show, create
  resources :share_links, only: [:index, :show, :create]

  # Ratings: only index, create, edit, update, destroy
  resources :ratings, only: [:index, :create, :edit, :update, :destroy]

  # Root path
  root "folders#index"
end
