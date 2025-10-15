# frozen_string_literal: true

# OmniAuth認証を処理するサービスクラス
# OAuth プロバイダからの認証情報を元にユーザーを検索または作成する
class OmniauthAuthenticationService
  # @param auth [OmniAuth::AuthHash] OmniAuthから取得した認証情報
  def initialize(auth)
    @auth = auth
    @provider = auth.provider.to_s
    @uid = auth.uid
    @email = extract_email
    @name = extract_name
  end

  # 認証情報を元にユーザーを検索または作成する
  # @return [User] 認証されたユーザー
  def call
    user = find_or_create_user
    log_result(user)
    user
  end

  private

  attr_reader :auth, :provider, :uid, :email, :name

  # メールアドレスを抽出する
  # OAuthプロバイダがメールアドレスを提供しない場合は代替のメールアドレスを生成
  # @return [String] メールアドレス
  def extract_email
    auth.info.email.presence || "#{uid}-#{provider}@example.com"
  end

  # 名前を抽出する
  # OAuthプロバイダが名前を提供しない場合はプロバイダ名を使用
  # @return [String] 名前
  def extract_name
    auth.info.name.presence || "#{provider.capitalize}ユーザー"
  end

  # ユーザーを検索または作成する
  # @return [User] ユーザー
  def find_or_create_user
    if google_oauth?
      find_or_create_google_user
    else
      find_or_create_oauth_user
    end
  end

  # Google OAuth認証かどうかを判定
  # @return [Boolean]
  def google_oauth?
    provider == "google_oauth2"
  end

  # Google OAuth用のユーザー検索または作成
  # 既存のメールアドレスがあれば紐付ける
  # @return [User] ユーザー
  def find_or_create_google_user
    user = User.find_by(email: email)

    if user
      update_oauth_credentials(user)
      user
    else
      create_oauth_user
    end
  end

  # 一般的なOAuth用のユーザー検索または作成
  # @return [User] ユーザー
  def find_or_create_oauth_user
    User.where(provider: provider, uid: uid).first_or_create do |user|
      set_user_attributes(user)
    end
  end

  # OAuth認証情報を既存ユーザーに紐付ける
  # @param user [User] 既存のユーザー
  def update_oauth_credentials(user)
    user.update(provider: provider, uid: uid)
  end

  # 新規ユーザーに属性を設定
  # @param user [User] 新規ユーザー
  def set_user_attributes(user)
    user.name = name
    user.email = email
    user.password = generate_password
    user.password_confirmation = user.password
  end

  # OAuth用の新規ユーザーを作成
  # @return [User] 作成されたユーザー
  def create_oauth_user
    password = generate_password
    User.create(
      provider: provider,
      uid: uid,
      name: name,
      email: email,
      password: password,
      password_confirmation: password
    )
  end

  # ランダムなパスワードを生成
  # @return [String] 生成されたパスワード
  def generate_password
    @generated_password ||= Devise.friendly_token[0, 20]
  end

  # ユーザー作成・更新結果をログに出力
  # @param user [User] 対象のユーザー
  def log_result(user)
    if user.persisted?
      Rails.logger.debug "User authenticated: #{user.inspect}"
    else
      Rails.logger.debug "User authentication failed: #{user.errors.full_messages}"
    end
  end
end
