# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ----------------------------------------
  # 基本設定
  # ----------------------------------------

  # コードはリクエスト間で再ロードしない
  config.enable_reloading = false

  # 起動時にすべてのコードを eager load
  config.eager_load = true

  # エラーレポートは抑制、キャッシュは有効化
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # マスターキーの必須化（必要ならコメント解除）
  # config.require_master_key = true

  # ----------------------------------------
  # アセット／静的ファイル配信
  # ----------------------------------------

  # アセットホストを apex ドメインに統一
  config.action_controller.asset_host = "https://fitgraph.jp"

  # public/ 以下から静的ファイルを配信（ファビコン等）
  config.public_file_server.enabled = true

  # 静的ファイルに長期キャッシュヘッダを追加
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=31536000"
  }
  # index.html 自動配信を無効化
  config.public_file_server.index_name = nil

  # アセットパイプラインのフォールバック禁止
  config.assets.compile = false

  # ----------------------------------------
  # SSL, ホスト制限
  # ----------------------------------------

  # 全トラフィックを HTTPS に強制リダイレクト
  config.force_ssl = true

  # DNS リバインディング対策ホスト許可
  config.hosts.clear
  config.hosts << "fitgraph.jp"
  config.hosts << "www.fitgraph.jp"

  # www.fitgraph.jp へのアクセスは apex にリダイレクト
  # rack-canonical_host gem が必要です
  config.middleware.insert_before 0, Rack::CanonicalHost, "fitgraph.jp"

  # ----------------------------------------
  # ロギング
  # ----------------------------------------

  config.logger = ActiveSupport::Logger.new(STDOUT)
                    .tap  { |l| l.formatter = ::Logger::Formatter.new }
                    .then { |l| ActiveSupport::TaggedLogging.new(l) }
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ----------------------------------------
  # ストレージ（Active Storage）
  # ----------------------------------------

  config.active_storage.service = :amazon

  # ----------------------------------------
  # メーラー
  # ----------------------------------------

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host:     "fitgraph.jp",
    protocol: "https"
  }
  config.action_mailer.smtp_settings = {
    address:              "smtp.gmail.com",
    port:                 587,
    domain:               "fitgraph.jp",
    user_name:            ENV["MAILER_SENDER"],
    password:             ENV["MAILER_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
  }

  # ----------------------------------------
  # I18n, Deprecations, Schema
  # ----------------------------------------

  config.i18n.fallbacks                  = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
