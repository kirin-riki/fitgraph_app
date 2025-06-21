class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  helper_method :icon_path, :dynamic_icon_path

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  private

  def icon_path(size = nil)
    # 新しい512x512pxのアイコンファイルを使用
    asset_path('icon_logo512.png')
  end

  def dynamic_icon_path(size = '192x192')
    # 将来的にActive Storageでアイコンを管理する場合の動的リサイズ
    # 現在は静的ファイルを使用
    icon_path(size)
  end
end
