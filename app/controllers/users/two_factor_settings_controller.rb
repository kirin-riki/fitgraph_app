class Users::TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    user = current_user || pre_2fa_user
    unless user
      redirect_to new_user_session_path, alert: "ログインし直してください"
      return
    end

    unless user.otp_secret
      user.otp_secret = User.generate_otp_secret
      user.save!
    end

    @otp_uri = user.otp_provisioning_uri(user.email, issuer: "FitGraph")
    qr = RQRCode::QRCode.new(@otp_uri)
    @qr_svg = qr.as_svg(module_size: 2)
  end

  def update
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.update!(otp_required_for_login: true)
      session[:just_enabled_2fa] = true
      redirect_to users_two_factor_settings_path, notice: "2段階認証を有効化しました"
    else
      flash.now[:alert] = "認証コードが正しくありません"
      show
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.valid_password?(params[:password])
      current_user.update!(otp_required_for_login: false, otp_secret: nil)
      redirect_to users_two_factor_settings_path, notice: "2段階認証を無効化しました"
    else
      flash.now[:alert] = "パスワードが正しくありません"
      render :show, status: :unprocessable_entity
    end
  end
end
