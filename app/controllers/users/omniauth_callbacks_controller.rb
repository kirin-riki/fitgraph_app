class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    callback_for(:google)
  end

  def line
    Rails.logger.debug "=== LINE認証/連携デバッグ ==="
    Rails.logger.debug "Current user present: \\#{current_user.present?}"
    Rails.logger.debug "Auth UID: \\#{request.env['omniauth.auth']&.dig('uid')}"

    auth = request.env['omniauth.auth']

    if current_user
      # 連携処理
      current_user.update(line_user_id: auth['uid'])
      redirect_to profile_path, notice: 'LINE連携が完了しました'
    else
      @user = User.from_omniauth(auth)
      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: 'LINE') if is_navigational_format?
      else
        session['devise.line_data'] = auth.except(:extra)
        redirect_to new_user_registration_url
      end
    end
  end

  def callback_for(provider)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end

  def failure
    unauthenticated_root_path
  end
end
