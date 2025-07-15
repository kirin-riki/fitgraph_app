class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :body_records
  has_many :recommended_videos
  has_many :favorite_videos, dependent: :destroy

  devise :database_authenticatable,
         :two_factor_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable,
         omniauth_providers: %i[google_oauth2 line], otp_secret_encryption_key: ENV["ENCRYPTION_KEY"]

  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:encrypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:encrypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:encrypted_password] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :uid, presence: true, uniqueness: { scope: :provider }, if: -> { uid.present? }

  def self.from_omniauth(auth)
    email = auth.info.email.presence || "#{auth.uid}-#{auth.provider}@example.com"
    name = auth.info.name.presence || "#{auth.provider.capitalize}ユーザー"

    # Google認証の場合、同じメールアドレスのユーザーがいれば紐付ける
    if auth.provider.to_s == "google_oauth2"
      user = find_by(email: email)
      if user
        user.update(provider: auth.provider, uid: auth.uid)
        return user
      end
    end

    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = name
      user.email = email
      pw = Devise.friendly_token[0, 20]
      user.password = pw
      user.password_confirmation = pw
    end

    if user.save
      Rails.logger.debug "User saved: \\#{user.inspect}"
    else
      Rails.logger.debug "User save failed: \\#{user.errors.full_messages}"
    end

    user
  end

  def self.create_unique_string
    SecureRandom.uuid
  end

  # QR 用 URI を組み立てるヘルパ（任意）
  def provisioning_uri(issuer: "MyApp")
    otp_provisioning_uri(email, issuer: issuer)
  end
end
