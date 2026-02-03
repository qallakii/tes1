Rails.application.routes.draw do
  root "sessions#new"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/signup", to: "users#new"
  resources :users, only: [:create]

  get "/dashboard", to: "folders#index"

  get "/search", to: "search#index", as: :search

  get "/s/:token", to: "share_links#show", as: :public_share

  resources :folders do
    member do
      patch :rename
      post  :bulk_move_items
      delete :bulk_destroy_items
      post  :bulk_download_items
      get   :download
    end

    collection do
      get  :download_all
      post :bulk_download
    end

    resources :cvs, only: [:new, :create, :destroy, :show, :update] do
      member do
        get :download
      end

      collection do
        delete :bulk_destroy
      end
    end
  end

  resources :share_links, only: [:index, :new, :create, :destroy, :show] do
    collection do
      post :bulk_create
      post :bulk_create_files
    end

    member do
      post  :unlock
      patch :toggle_disabled

      # Public, permission-checked preview/download (uses existing controller actions)
      get "files/:cv_id/preview",  to: "share_links#preview",  as: :file_preview
      get "files/:cv_id/download", to: "share_links#download", as: :file_download
    end
  end

  get "/recents", to: "recents#index", as: :recents
  resources :recents, only: [:index]
end
