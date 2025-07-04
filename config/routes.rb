Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", passwords: "users/passwords" }
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "progress", to: "progress#index"

  authenticated :user do
    root "body_records#top", as: :authenticated_root
  end
  unauthenticated do
    root "static_pages#top", as: :unauthenticated_root
  end
  resources :users, only: %i[new create]
  resource :profile, only: %i[show edit update]
  resources :body_records, only: %i[new create show edit update] do
    collection do
      get :top
    end
  end
  resources :recommended_videos, only: [ :index ] do
    collection do
      post :refresh
      get :refresh
    end
  end
  resources :favorite_videos, only: [ :create, :destroy ]
  
  # LINE Bot Webhook
  post "line/callback" => "line_bot#callback"
end
