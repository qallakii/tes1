Rails.application.routes.draw do
  # -----------------------------
  # Devise routes for user auth
  # -----------------------------
  devise_for :users

  # -----------------------------
  # Folders and nested CVs
  # -----------------------------
  resources :folders do
    resources :cvs, only: [:index, :new, :create, :show, :destroy] do
      # Ratings nested under CVs
      resources :ratings, only: [:create]
    end

    # ShareLinks nested under Folders
    resources :share_links, only: [:create, :show]
  end

  # -----------------------------
  # Additional standalone routes if needed
  # -----------------------------
  # resources :cvs, only: [:show, :destroy] # optional, if you want non-nested access
  # resources :ratings, only: [:create]     # optional, if not nested

  # -----------------------------
  # Root path
  # -----------------------------
  root "folders#index"
end
