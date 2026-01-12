Rails.application.routes.draw do
  root "sessions#new"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/signup", to: "users#new"
  resources :users, only: [:create]

  get "/dashboard", to: "folders#index"

  get "/search", to: "search#index", as: :search

  resources :folders do
    resources :cvs, only: [:new, :create, :destroy, :show, :index, :update] do
      collection do
        delete :bulk_destroy
      end
    end
  end

  resources :share_links, only: [:index, :new, :create, :destroy, :show]
  
  resources :recents, only: [:index]
end
