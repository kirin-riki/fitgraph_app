class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_default_meta_tags

  helper_method :icon_path
  add_flash_types :success, :danger

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  private

  def set_default_meta_tags
    @page_title = "FitGraph"
    @page_description = "FitGraphは、日々のフィットネス活動を記録し、グラフで可視化することで、あなたのモチベーションを高め、目標達成をサポートするアプリです。"
    @page_keywords = "フィットネス, 筋トレ, 記録, グラフ, ダイエット, 健康管理, トレーニング"
  end

  def default_meta_tags
    {
      site: @page_title,
      title: "",
      reverse: true,
      separator: "|",
      description: @page_description,
      keywords: @page_keywords,
      canonical: request.original_url,
      og: {
        title: :full_title,
        type: "website",
        site_name: :site,
        description: :description,
        image: image_url("ogp.png"),
        url: :canonical
      },
      twitter: {
        card: "summary_large_image",
        site: "@YourTwitterAccount", # あなたのTwitterアカウントがあれば設定
        image: image_url("ogp.png")
      }
    }
  end

  def icon_path(size = nil)
    # 新しい512x512pxのアイコンファイルを使用
    asset_path("icon_logo512.png")
  end

  # 未ログイン時は未認証トップページにリダイレクト
  def authenticate_user!
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "ログインが必要です。"
    end
  end

  # Deviseのリダイレクト先もrootに
  def after_sign_in_path_for(resource)
    authenticated_root_path
  end
end
