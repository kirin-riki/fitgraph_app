class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :body_records
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
    OmniauthAuthenticationService.new(auth).call
  end

  def self.create_unique_string
    SecureRandom.uuid
  end

  # QR 用 URI を組み立てるヘルパ（任意）
  def provisioning_uri(issuer: "Fitgraph")
    TwoFactorAuthService.new(self, issuer: issuer).provisioning_uri
  end
end
