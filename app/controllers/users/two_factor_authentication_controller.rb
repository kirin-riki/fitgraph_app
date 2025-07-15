class Users::TwoFactorAuthenticationController < ApplicationController
  before_action :require_pre_2fa_user

  def new
    @user = pre_2fa_user
  end

  def create
    @user = pre_2fa_user
    if @user&.validate_and_consume_otp!(params[:otp_attempt])
      session.delete(:user_id)
      session[:two_factor_authenticated] = true
      sign_in(:user, @user)
      redirect_to authenticated_root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "認証コードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_pre_2fa_user
    redirect_to new_user_session_path, alert: "ログイン情報が見つかりません" unless pre_2fa_user
  end
end
