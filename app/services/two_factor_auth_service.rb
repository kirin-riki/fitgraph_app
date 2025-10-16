# frozen_string_literal: true

# 二要素認証(2FA)を処理するサービスクラス
# QRコードの生成とOTP検証を担当する
class TwoFactorAuthService
  # @param user [User] 二要素認証を設定するユーザー
  # @param issuer [String] OTPの発行者名(アプリ名など)
  def initialize(user, issuer: "Fitgraph")
    @user = user
    @issuer = issuer
  end

  # OTP用のprovisioning URIを生成する
  # @return [String] OTP用のURI
  def provisioning_uri
    user.otp_provisioning_uri(user.email, issuer: issuer)
  end

  # QRコード用のprovisioning URIを生成する(エイリアス)
  # @return [String] OTP用のURI
  def qr_code_uri
    provisioning_uri
  end

  private

  attr_reader :user, :issuer
end
