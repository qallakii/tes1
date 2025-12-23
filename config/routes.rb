Rails.application.routes.draw do
  root "folders#index"

  # User authentication
  get  "/signup", to: "users#new"
  post "/signup", to: "users#create"
  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"

  # Logout: DELETE preferred, GET fallback
  delete "/logout", to: "sessions#destroy"
  get    "/logout", to: "sessions#destroy"

  resources :users, only: [:new, :create]

  resources :folders, only: [:index, :show, :new, :create] do
    resources :cvs, only: [:index, :new, :create, :show, :destroy]
  end
end
