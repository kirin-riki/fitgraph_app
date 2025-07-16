class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    callback_for(:google)
  end

  def line
    if user_signed_in?
      link_line_account
    else
      line_login_action
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
    redirect_to unauthenticated_root_path, alert: "認証に失敗しました"
  end

  private

  # LINEログイン（未ログイン時）
  def line_login_action
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "LINE") if is_navigational_format?
    else
      session["devise.line_data"] = auth.except(:extra)
      redirect_to new_user_registration_url
    end
  end

  # LINE連携（ログイン済み時）
  def link_line_account
    auth = request.env["omniauth.auth"]

    # omniauthの情報が正しいか確認
    unless auth && auth["provider"].present? && auth["uid"].present?
      flash[:alert] = "LINE連携に失敗しました"
      return redirect_to profile_path
    end

    # LINEのuidが他ユーザーに紐付いていないかチェック
    if User.exists?(line_user_id: auth["uid"])
      flash[:alert] = "このLINEアカウントは既に他のユーザーに連携されています"
    else
      current_user.update!(line_user_id: auth["uid"])
      flash[:notice] = "LINEアカウントを連携しました"
    end
    redirect_to profile_path
  end
end
