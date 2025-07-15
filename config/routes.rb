Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  devise_for :users, controllers: {
    sessions: "users/sessions",
    two_factor_authentication: "users/two_factor_authentication",
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "users/passwords"
  }

  # 2FA認証用のルートを明示的に追加
  devise_scope :user do
    get "users/two_factor_authentication/new", to: "users/two_factor_authentication#new", as: :new_user_two_factor_authentication
    post "users/two_factor_authentication", to: "users/two_factor_authentication#create", as: :user_two_factor_authentication
  end
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
  namespace :users do
    resource :two_factor_settings, only: [ :show, :update, :destroy ]
  end
  # LINE Bot Webhook
  post "line/callback" => "line_bot#callback"

  get "terms", to: "static_pages#terms", as: :terms
  get "privacy", to: "static_pages#privacy", as: :privacy
  get "how_to", to: "static_pages#how_to", as: :how_to
end
