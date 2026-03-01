Rails.application.routes.draw do
  # ========================
  # Devise / 認証関連
  # ========================
  devise_for :users, controllers: {
    sessions: "users/sessions",
    two_factor_authentication: "users/two_factor_authentication",
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "users/passwords"
  }

  # 2FA 認証用ルート
  devise_scope :user do
    get  "users/two_factor_authentication/new",
         to: "users/two_factor_authentication#new",
         as: :new_user_two_factor_authentication

    post "users/two_factor_authentication",
         to: "users/two_factor_authentication#create",
         as: :user_two_factor_authentication
  end

  # ========================
  # 開発・監視系
  # ========================
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  get "up", to: "rails/health#show", as: :rails_health_check

  # PWA 関連
  get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest",        to: "rails/pwa#manifest",        as: :pwa_manifest

  # ========================
  # メイン機能
  # ========================
  authenticated :user do
    root "body_records#top", as: :authenticated_root
  end
  unauthenticated do
    root "static_pages#top", as: :unauthenticated_root
  end

  # プロフィール / ユーザー
  resource  :profile, only: %i[show edit update]
  resources :users,   only: %i[new create]

  # 身体情報
  resources :body_records, only: %i[new create show edit update] do
    collection do
      get :top
    end
  end

  # 経過（グラフ・写真）
  get "progress", to: "progress#index"

  # 動画関連
  resources :recommended_videos, only: [ :index ] do
    collection do
      post :refresh
      get  :refresh
    end
  end
  resources :favorite_videos, only: [ :create, :destroy ]

  namespace :users do
    resource :two_factor_settings, only: [ :show, :update, :destroy ]
  end

  # ========================
  # 外部連携 / 静的ページ
  # ========================
  # LINE Bot Webhook
  post "line/callback", to: "line_bot#callback"

  # 静的ページ
  get "terms",   to: "static_pages#terms",   as: :terms
  get "privacy", to: "static_pages#privacy", as: :privacy
  get "how_to",  to: "static_pages#how_to",  as: :how_to
end
