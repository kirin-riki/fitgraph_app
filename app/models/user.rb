class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :body_records
  has_many :recommended_videos, dependent: :destroy
  has_many :favorite_videos, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:encrypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:encrypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:encrypted_password] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :uid, presence: true, uniqueness: { scope: :provider }, if: -> { uid.present? }

  def self.from_omniauth(auth)
    # 以下1行[user = where ...]コメントアウト
    # user = where(provider: auth.provider, uid: auth.uid).first_or_initialize

    # 以下の頭に[user = ]を追加
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth.info.name
      user.email = auth.info.email
      pw = Devise.friendly_token[0, 20]
      user.password = pw
      user.password_confirmation = pw
    end

    # デバッグ：エラーが出た時にどのようなエラーが出るか確認。
    if user.save
      Rails.logger.debug "User saved: #{user.inspect}"
    else
      Rails.logger.debug "User save failed: #{user.errors.full_messages}"
    end

    user
  end

  def self.create_unique_string
    SecureRandom.uuid
  end
end
