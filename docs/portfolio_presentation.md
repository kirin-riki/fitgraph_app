# FITGRAPH ポートフォリオプレゼンテーション資料

## 目次
1. [テーブル設計](#1-テーブル設計)
2. [システム要件](#2-システム要件)
3. [技術選定の根拠](#3-技術選定の根拠)
4. [コードの概要](#4-コードの概要)

---

## 1. テーブル設計

### 1.1 テーブル一覧と役割

FITGRAPHアプリケーションは、以下の6つの主要テーブルで構成されています。

| テーブル名 | 役割 | 主要カラム |
|-----------|------|-----------|
| `users` | ユーザー認証情報 | email, name, password, OAuth認証情報 |
| `profiles` | ユーザープロフィール | height, gender, training_intensity, target_weight |
| `body_records` | 身体情報の記録 | weight, body_fat, fat_mass, recorded_at, photo |
| `favorite_videos` | お気に入り動画 | youtube_url, title, thumbnail_url |
| `recommended_videos` | おすすめ動画キャッシュ | video_id, title, view_count, condition_key |
| `active_storage_*` | 画像ファイル管理 | Rails標準のActive Storage |

### 1.2 詳細テーブル設計

#### 1.2.1 usersテーブル（ユーザー認証情報）

```ruby
create_table "users" do |t|
  # 基本情報
  t.string   "name",                null: false              # ユーザー名
  t.string   "email",               null: false              # メールアドレス
  t.string   "encrypted_password",  default: "", null: false # 暗号化パスワード

  # OAuth認証用
  t.string   "provider"                                      # 認証プロバイダー(google_oauth2/line)
  t.string   "uid"                                           # プロバイダーのユーザーID
  t.string   "line_user_id"                                  # LINE連携ID

  # パスワードリセット用
  t.string   "reset_password_token"
  t.datetime "reset_password_sent_at"

  # 二要素認証(2FA)用
  t.string   "otp_secret"                                    # ワンタイムパスワードのシークレット
  t.integer  "consumed_timestep"                             # 使用済みタイムステップ
  t.boolean  "otp_required_for_login"                        # 2FA有効フラグ

  # ログイン記憶
  t.datetime "remember_created_at"

  # タイムスタンプ
  t.datetime "created_at",          null: false
  t.datetime "updated_at",          null: false

  # インデックス
  t.index ["email"], unique: true
  t.index ["uid", "provider"], unique: true
  t.index ["line_user_id"], unique: true
end
```

**設計のポイント:**
- `email`をユニークキーとして、メールアドレスベースのログインに対応
- `provider`と`uid`の組み合わせで、GoogleとLINEのOAuth認証に対応
- `otp_secret`により二要素認証(2FA)をサポートし、セキュリティを強化
- パスワードリセット機能に対応

#### 1.2.2 profilesテーブル（ユーザープロフィール）

```ruby
create_table "profiles" do |t|
  t.bigint  "user_id",            null: false              # 外部キー: users
  t.integer "height"                                       # 身長(cm)
  t.integer "gender",             default: 0, null: false  # 性別(enum: 0=man, 1=woman, 2=other)
  t.integer "training_intensity", default: 0, null: false  # 運動強度(enum: 0=low, 1=medium, 2=high)
  t.integer "target_weight"                                # 目標体重(kg)
  t.date    "start_date"                                   # ダイエット開始日

  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["user_id"], unique: true  # 1ユーザー1プロフィール
end
```

**設計のポイント:**
- ユーザーとは1対1の関係（`user_id`にユニーク制約）
- `gender`と`training_intensity`をenumで管理し、コード上での可読性を向上
- これらの値を組み合わせた`condition_key`（例: "man_low"）でYouTube動画の検索条件を決定
- `target_weight`により目標体重までのカウントダウン機能を実現

#### 1.2.3 body_recordsテーブル（身体情報の記録）

```ruby
create_table "body_records" do |t|
  t.bigint   "user_id",     null: false                    # 外部キー: users
  t.datetime "recorded_at", null: false                    # 記録日時
  t.decimal  "weight",      precision: 5, scale: 2         # 体重(kg) 例: 123.45
  t.decimal  "body_fat",    precision: 4, scale: 1         # 体脂肪率(%) 例: 23.5
  t.decimal  "fat_mass",    precision: 5, scale: 2         # 脂肪量(kg) 例: 28.91

  t.datetime "created_at",  null: false
  t.datetime "updated_at",  null: false

  # インデックス
  t.index ["user_id"]
  t.index ["user_id", "recorded_at"], unique: true  # 1日1レコード制約
end

# 画像は Active Storage で管理（has_one_attached :photo）
```

**設計のポイント:**
- `recorded_at`により日付単位での記録管理
- `user_id`と`recorded_at`の複合ユニーク制約で、1日1レコードを保証
- `decimal`型で小数点以下の精度を確保（体重: 小数点2桁、体脂肪率: 小数点1桁）
- `fat_mass`は計算値（体重 × 体脂肪率 / 100）だが、高速化のため保存
- 写真はActive Storageの`has_one_attached`で管理し、テーブルは分離

#### 1.2.4 favorite_videosテーブル（お気に入り動画）

```ruby
create_table "favorite_videos" do |t|
  t.bigint  "user_id",       null: false  # 外部キー: users
  t.string  "youtube_url",   null: false  # YouTube動画URL
  t.string  "title",         null: false  # 動画タイトル
  t.string  "thumbnail_url", null: false  # サムネイル画像URL
  t.string  "channel_title"              # チャンネル名

  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["user_id"]
end
```

**設計のポイント:**
- ユーザーごとに複数のお気に入り動画を保存
- YouTube APIから取得した動画情報をキャッシュし、API呼び出しを削減
- `youtube_url`にはフルURLを保存し、外部サイトへのリンクに使用

#### 1.2.5 recommended_videosテーブル（おすすめ動画キャッシュ）

```ruby
create_table "recommended_videos" do |t|
  t.string   "video_id",      null: false  # YouTube動画ID
  t.string   "title",         null: false  # 動画タイトル
  t.string   "thumbnail_url"              # サムネイル画像URL
  t.string   "channel_title"              # チャンネル名
  t.integer  "view_count"                 # 再生回数
  t.datetime "fetched_at",    null: false  # APIから取得した日時
  t.string   "condition_key"              # 検索条件キー(例: "man_low")

  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["video_id"]
  t.index ["fetched_at"]
end
```

**設計のポイント:**
- YouTube Data APIから取得した動画情報をキャッシュ
- `condition_key`により、性別×運動強度の組み合わせごとに動画を保存
- `fetched_at`でキャッシュの鮮度を管理し、古いデータは再取得
- APIのクォータ制限対策として重要な役割

#### 1.2.6 Active Storageテーブル（画像ファイル管理）

```ruby
# active_storage_blobs: ファイル本体のメタデータ
create_table "active_storage_blobs" do |t|
  t.string   "key",          null: false  # ユニークなファイル識別子
  t.string   "filename",     null: false  # 元のファイル名
  t.string   "content_type"              # MIMEタイプ
  t.text     "metadata"                   # JSONメタデータ
  t.string   "service_name", null: false  # ストレージサービス名(local/s3など)
  t.bigint   "byte_size",    null: false  # ファイルサイズ
  t.string   "checksum"                   # ファイル整合性チェック用

  t.datetime "created_at", null: false
end

# active_storage_attachments: モデルとファイルの関連付け
create_table "active_storage_attachments" do |t|
  t.string "name",        null: false  # アタッチメント名(例: "photo")
  t.string "record_type", null: false  # モデル名(例: "BodyRecord")
  t.bigint "record_id",   null: false  # モデルのID
  t.bigint "blob_id",     null: false  # 外部キー: active_storage_blobs

  t.datetime "created_at", null: false

  t.index ["record_type", "record_id", "name", "blob_id"], unique: true
end
```

**設計のポイント:**
- Rails標準のActive Storageを使用し、ファイル管理を簡素化
- ポリモーフィック関連により、複数のモデルで同じテーブルを共有可能
- 本番環境ではAWS S3などのクラウドストレージに対応可能

### 1.3 テーブル間のリレーションシップ

```
users (1) ──────── (1) profiles
  │
  ├─ (1) ──────── (多) body_records ──────── (1) photo [Active Storage]
  │
  ├─ (1) ──────── (多) favorite_videos
  │
  └─ プロフィール情報で recommended_videos を検索
                   (direct relationなし、condition_keyで紐付け)
```

**主要な関連:**
- `User` has_one `Profile`（1対1）
- `User` has_many `BodyRecords`（1対多）
- `User` has_many `FavoriteVideos`（1対多）
- `BodyRecord` has_one_attached `photo`（Active Storage経由）
- `RecommendedVideo`はユーザーと直接の関連を持たず、`condition_key`で間接的に紐付け

### 1.4 データベース設計の工夫点

#### 1.4.1 パフォーマンス最適化
- 頻繁に検索されるカラムにインデックスを設定
  - `users.email`、`body_records.user_id`、`body_records.recorded_at`など
- 複合ユニークインデックス（`user_id` + `recorded_at`）で重複データを防止

#### 1.4.2 データ整合性
- 外部キー制約で親子関係を保証
- NOT NULL制約で必須項目を明確化
- ユニーク制約で重複を防止

#### 1.4.3 拡張性
- enumによる状態管理で、将来的な選択肢追加に対応
- Active Storageにより、ストレージサービスの変更が容易
- `condition_key`によるキャッシュ戦略で、APIクォータ制限に対応

---

## 2. システム要件

### 2.1 機能要件

#### 2.1.1 ユーザー認証・セキュリティ機能

**アカウント管理**
- メールアドレス/パスワードによるユーザー登録・ログイン
- Google OAuth 2.0による認証（Googleアカウントでログイン）
- LINE OAuth 2.0による認証（LINEアカウントでログイン）
- パスワードリセット機能（メール経由）
- 二要素認証(2FA)の有効化/無効化（QRコード生成、ワンタイムパスワード検証）

**セキュリティ要件**
- パスワードは6文字以上、bcryptで暗号化
- 二要素認証はTOTP（Time-based One-Time Password）方式
- OAuth認証では既存ユーザーとの自動紐付け（Googleの場合、メールアドレスで照合）
- CSRF保護（OmniAuthでのCSRF対策）

#### 2.1.2 プロフィール管理機能

**基本情報登録**
- 身長（cm）
- 性別（男性/女性/その他）
- トレーニング強度（低/中/高）
- 目標体重（kg）
- ダイエット開始日

**ビジネスロジック**
- 性別とトレーニング強度の組み合わせ（condition_key）を自動生成
- この組み合わせがYouTube動画のレコメンドに使用される

#### 2.1.3 身体情報記録機能

**記録項目**
- 日付（必須）
- 体重（任意、kg、小数点2桁）
- 体脂肪率（任意、%、小数点1桁）
- 脂肪量（任意、kg、自動計算: 体重 × 体脂肪率 / 100）
- 身体写真（任意、Active Storage経由）

**記録のルール**
- 1日1レコードまで（同じ日付には上書き更新）
- カレンダー形式で日付を選択可能
- 写真はWebカメラでの撮影またはファイルアップロード
- バリデーション:
  - 体重: 0〜300kg
  - 体脂肪率: 0〜100%

#### 2.1.4 経過表示機能（Progressページ）

**グラフ表示**
- 体重と体脂肪率の折れ線グラフ（Chart.js使用）
- 期間選択: 1週間/3週間/1ヶ月/3ヶ月
- 二軸グラフ（左軸: 体重、右軸: 体脂肪率）
- 目標体重を破線で表示
- レスポンシブ対応（モバイル/デスクトップで表示調整）

**統計表示**
- 期間内の最初と最後の値を比較
- 表示項目: 体重、体脂肪率、脂肪量
- 目標体重までの残り（カウントダウン）
- 目標達成時の表示切り替え

**写真表示**
- レイヤービュー: スライダーで複数の写真を切り替え
- 比較ビュー: Before/Afterで2枚の写真を並べて表示
- 期間フィルタ: 1週間/3週間/1ヶ月/3ヶ月
- プレースホルダー画像（写真未登録時）

#### 2.1.5 YouTube動画レコメンド機能

**おすすめ動画表示**
- ユーザーのプロフィール（性別×トレーニング強度）に基づいて動画を提案
- YouTube Data API v3から動画を検索
- 検索キーワードは外部YAML設定ファイルで管理（`config/youtube_keywords.yml`）
- 動画情報をキャッシュし、APIクォータを節約

**検索条件の例**
- `man_low`: "初心者 有酸素 トレーニング ダンス 家"
- `woman_high`: "有酸素 自重トレーニング 家"

**キャッシュ戦略**
- 取得済み動画は`recommended_videos`テーブルに保存
- 鮮度管理: `fetched_at`で取得日時を記録
- 手動更新: ユーザーが「更新」ボタンで再取得

**お気に入り機能**
- ユーザーが任意の動画をお気に入りに追加
- お気に入り一覧をマイページで表示
- YouTube URLから動画情報を自動取得

#### 2.1.6 LINE Bot連携機能

**リマインド通知**
- LINEアカウントと連携
- 指定時刻にトレーニングのリマインド通知を送信
- Webhook経由でユーザーからのメッセージに応答

**技術仕様**
- LINE Messaging API使用
- `line_user_id`でユーザーを識別
- 定期通知はcronやバックグラウンドジョブで実装想定

#### 2.1.7 静的ページ機能

- トップページ（未ログイン時）
- 利用規約ページ
- プライバシーポリシーページ
- 使い方ページ（アコーディオン形式のFAQ）

### 2.2 非機能要件

#### 2.2.1 パフォーマンス要件
- ページ読み込み時間: 3秒以内（通常時）
- グラフ描画: 1秒以内
- 画像の最適化:
  - アップロード時に自動リサイズ（Active Storageのvariant機能）
  - サムネイル生成: 400x600px、JPEG、品質70%
- データベースクエリの最適化:
  - N+1問題の回避（eager loadingの活用）
  - インデックスの適切な設定

#### 2.2.2 可用性要件
- 稼働率: 99%以上（月間ダウンタイム7時間以内）
- エラー時のフォールバック:
  - YouTube API障害時は空配列を返す
  - 画像読み込み失敗時はプレースホルダー表示

#### 2.2.3 セキュリティ要件
- HTTPS通信必須（本番環境）
- パスワードのbcrypt暗号化（コストファクター12）
- 二要素認証の推奨（必須ではない）
- CSRF保護（Rails標準機能）
- 環境変数による機密情報管理（dotenv-rails使用）
  - YouTube API Key
  - OAuth Client ID/Secret
  - LINE Bot Token
  - AWS S3認証情報

#### 2.2.4 スケーラビリティ要件
- ユーザー数: 初期1,000ユーザー想定
- 画像ストレージ: AWS S3使用でスケーラブル
- データベース: PostgreSQL（水平スケーリング可能）
- CDN: 静的アセットのキャッシュ

#### 2.2.5 運用要件
- ログ管理: Railsログ、エラーログ
- バックアップ: データベース日次バックアップ
- モニタリング: Render標準機能による稼働監視
- CI/CD: GitHub Actionsによる自動テスト・デプロイ

#### 2.2.6 互換性要件
- ブラウザ対応:
  - Chrome（最新版）
  - Safari（最新版）
  - Firefox（最新版）
  - Edge（最新版）
- モバイル対応: レスポンシブデザイン（Tailwind CSS使用）
- API互換性:
  - YouTube Data API v3
  - LINE Messaging API

---

## 3. 技術選定の根拠

### 3.1 バックエンド技術

#### 3.1.1 Ruby on Rails 7.2.1
**選定理由:**
- **高速開発**: Railsの「設定より規約」により、短期間での開発が可能
- **豊富なGem**: 認証（Devise）、画像処理（Active Storage）、OAuth（OmniAuth）など、必要な機能がGemで提供
- **MVCアーキテクチャ**: モデル・ビュー・コントローラーの分離で保守性が高い
- **Active Record**: O/Rマッパーによりデータベース操作が直感的
- **セキュリティ**: CSRF保護、SQLインジェクション対策が標準装備

**このプロジェクトでの活用:**
- Deviseによるユーザー認証の実装
- Active Storageによる画像アップロード管理
- OmniAuthによるGoogle/LINE OAuth連携
- Service Objectパターンによるビジネスロジックの分離

#### 3.1.2 Ruby 3.3.6
**選定理由:**
- Ruby 3.xシリーズの安定版
- パフォーマンス向上（YJIT、Ractor、Fiber Schedulerなど）
- Rails 7.2との互換性

#### 3.1.3 PostgreSQL
**選定理由:**
- **堅牢性**: ACID特性を満たす信頼性の高いRDBMS
- **豊富なデータ型**: JSONBなど、将来的な拡張に対応
- **Rails標準**: Active Recordとの親和性が高い
- **本番環境対応**: Renderなどのホスティングサービスで標準サポート

**代替案との比較:**
- MySQL: 一般的だが、PostgreSQLの方が高機能
- SQLite: 開発環境では軽量だが、本番環境には不向き

### 3.2 フロントエンド技術

#### 3.2.1 Hotwire (Turbo + Stimulus)
**選定理由:**
- **Rails標準**: Rails 7でデフォルト採用
- **軽量**: JavaScriptフレームワーク不要で学習コストが低い
- **高速なページ遷移**: Turboによるpjax風のページ更新
- **インタラクティブ性**: Stimulusによる最小限のJavaScript制御

**このプロジェクトでの活用:**
- Turbo: ページ遷移の高速化（ヘッダー/フッターを再描画しない）
- Stimulus: カレンダー選択、写真スライダー、グラフ期間切り替えのインタラクティブ制御

#### 3.2.2 Tailwind CSS + DaisyUI
**選定理由:**
- **ユーティリティファースト**: HTMLに直接クラスを記述し、高速に開発
- **レスポンシブデザイン**: モバイルファーストの設計
- **カスタマイズ性**: `tailwind.config.js`で柔軟にデザイン調整
- **DaisyUI**: Tailwind CSSのコンポーネントライブラリで、ボタンやカードのデザインを簡素化

**代替案との比較:**
- Bootstrap: コンポーネントベースだが、カスタマイズが煩雑
- CSS Modules: Reactなどに適しているが、Railsでは冗長

#### 3.2.3 Chart.js
**選定理由:**
- **軽量**: 依存が少なく、バンドルサイズが小さい
- **レスポンシブ**: モバイル対応が標準
- **豊富なグラフ種類**: 折れ線グラフ、二軸グラフに対応
- **カスタマイズ性**: プラグインで目標体重の可視化など拡張可能

**このプロジェクトでの活用:**
- 体重・体脂肪率の二軸折れ線グラフ
- カスタムプラグインで目標体重を破線で表示
- 期間切り替え（1週間〜3ヶ月）に対応

#### 3.2.4 esbuild
**選定理由:**
- **高速ビルド**: GoによるビルドツールでVite並みの速度
- **ES Modules対応**: モダンなJavaScript構文
- **jsbundling-rails**: Rails 7標準のJavaScriptバンドラー

### 3.3 外部API・サービス

#### 3.3.1 YouTube Data API v3
**選定理由:**
- **公式API**: Google公式の安定したAPI
- **豊富な検索オプション**: キーワード、動画の長さ、関連性などでフィルタ可能
- **無料枠**: 1日あたり10,000クォータ（検索1回=100クォータ）

**このプロジェクトでの活用:**
- ユーザーのプロフィール（性別×トレーニング強度）に基づいて動画を検索
- 検索結果を`recommended_videos`テーブルにキャッシュし、API呼び出しを削減
- エラーハンドリング: タイムアウト、リトライ、フォールバック

#### 3.3.2 Google OAuth 2.0
**選定理由:**
- **ユーザビリティ**: Googleアカウントで簡単にログイン
- **セキュリティ**: OAuth 2.0標準プロトコル
- **メール取得**: ユーザーのメールアドレスを自動取得

**実装:**
- `omniauth-google-oauth2` gemを使用
- 既存ユーザーとの自動紐付け（メールアドレス照合）

#### 3.3.3 LINE Messaging API
**選定理由:**
- **国内普及率**: 日本で最も使われるメッセージングアプリ
- **Push通知**: トレーニングのリマインド通知に最適
- **Webhook対応**: ユーザーからのメッセージに自動応答

**実装:**
- `line-bot-api` gemを使用
- `line_user_id`でユーザーを識別
- Webhook経由でメッセージ受信

### 3.4 インフラ・デプロイ

#### 3.4.1 Docker + Docker Compose
**選定理由:**
- **環境統一**: 開発・本番環境の差異を最小化
- **依存管理**: PostgreSQL、Redis（将来）などのミドルウェアをコンテナ化
- **ポータビリティ**: どの環境でも同じ構成で動作

**このプロジェクトでの構成:**
```yaml
services:
  web:      # Rails アプリケーション
  db:       # PostgreSQL
  # 将来的にRedis、Sidekiqなどを追加可能
```

#### 3.4.2 Render
**選定理由:**
- **簡単デプロイ**: GitHubと連携し、pushで自動デプロイ
- **無料プラン**: 小規模アプリに最適
- **PostgreSQL標準**: マネージドデータベース
- **環境変数管理**: 環境変数の安全な管理

**代替案との比較:**
- Heroku: 無料プランが廃止
- AWS: 高機能だが、設定が複雑で学習コスト高
- Railway: 良い選択肢だが、Renderの方が実績豊富

#### 3.4.3 AWS S3（画像ストレージ）
**選定理由:**
- **スケーラビリティ**: 無制限のストレージ
- **コスト**: 従量課金で初期費用不要
- **Active Storage対応**: Railsから簡単に利用可能

### 3.5 認証・セキュリティ

#### 3.5.1 Devise
**選定理由:**
- **Rails標準**: 最も使われている認証Gem
- **豊富な機能**: ログイン、ログアウト、パスワードリセット、メール確認など
- **拡張性**: OmniAuth、2FAなどのモジュールと統合可能

#### 3.5.2 devise-two-factor + ROTP + RQRCode
**選定理由:**
- **セキュリティ強化**: 二要素認証でアカウント乗っ取りを防止
- **TOTP標準**: Google Authenticatorなどの認証アプリに対応
- **QRコード生成**: RQRCodeでユーザーが簡単に設定可能

### 3.6 開発・テスト

#### 3.6.1 RSpec + Factory Bot
**選定理由:**
- **BDD**: Behavior-Driven Developmentでテストコードが読みやすい
- **Factory Bot**: テストデータの作成が簡潔
- **Shoulda Matchers**: バリデーションのテストを簡素化

**このプロジェクトでのテスト:**
- モデルテスト: バリデーション、アソシエーション
- サービステスト: ビジネスロジック
- システムテスト: ユーザーの操作フロー（Capybara + Selenium）

#### 3.6.2 RuboCop
**選定理由:**
- **コード品質**: Rubyコミュニティのベストプラクティスに準拠
- **自動修正**: 単純な問題は自動で修正可能

### 3.7 技術スタック全体図

```
【フロントエンド】
├─ Tailwind CSS + DaisyUI (スタイリング)
├─ Hotwire (Turbo + Stimulus)
├─ Chart.js (グラフ描画)
└─ esbuild (JavaScriptバンドラー)

【バックエンド】
├─ Ruby 3.3.6
├─ Rails 7.2.1
│   ├─ Active Record (ORM)
│   ├─ Active Storage (画像管理)
│   └─ Action Mailer (メール送信)
├─ Devise + OmniAuth (認証)
└─ Service Objects (ビジネスロジック)

【データベース】
└─ PostgreSQL

【外部API】
├─ YouTube Data API v3
├─ Google OAuth 2.0
└─ LINE Messaging API

【インフラ】
├─ Docker + Docker Compose
├─ Render (ホスティング)
└─ AWS S3 (画像ストレージ)

【開発・テスト】
├─ RSpec + Factory Bot
├─ Capybara + Selenium
├─ RuboCop
└─ GitHub Actions (CI/CD)
```

---

## 4. コードの概要

### 4.1 アーキテクチャ

FITGRAPHは、Rails標準のMVCアーキテクチャに加え、**Service Object パターン**を採用しています。

```
app/
├── controllers/       # ユーザーリクエストの処理
├── models/            # データモデルとバリデーション
├── views/             # HTMLテンプレート
├── services/          # ビジネスロジック（Service Object パターン）
├── javascript/        # Stimulus コントローラー、Chart.js
└── assets/            # CSS、画像
```

### 4.2 主要なコンポーネント

#### 4.2.1 モデル層（Models）

**User モデル** (`app/models/user.rb`)
```ruby
class User < ApplicationRecord
  # アソシエーション
  has_one :profile, dependent: :destroy
  has_many :body_records
  has_many :favorite_videos, dependent: :destroy

  # Devise モジュール
  devise :database_authenticatable,
         :two_factor_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable,
         omniauth_providers: %i[google_oauth2 line]

  # OAuth認証からユーザーを作成/取得
  def self.from_omniauth(auth)
    # Google認証の場合、同じメールアドレスのユーザーに紐付ける
    # LINE認証の場合、uid+providerで識別
  end

  # 二要素認証のQRコード用URI
  def provisioning_uri(issuer: "MyApp")
    otp_provisioning_uri(email, issuer: issuer)
  end
end
```

**主要な機能:**
- Deviseによる認証（パスワード、OAuth、2FA）
- OAuth認証時の自動ユーザー作成/紐付け
- プロフィール、身体記録、お気に入り動画との関連

---

**BodyRecord モデル** (`app/models/body_record.rb`)
```ruby
class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo  # Active Storage

  validates :weight, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 300
  }, allow_nil: true

  validates :body_fat, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }, allow_nil: true
end
```

**主要な機能:**
- 体重・体脂肪率・脂肪量の記録
- Active Storageによる写真管理
- バリデーションで不正値を防止

---

**Profile モデル** (`app/models/profile.rb`)
```ruby
class Profile < ApplicationRecord
  belongs_to :user

  enum :gender, { man: 0, woman: 1, other: 2 }
  enum :training_intensity, { low: 0, medium: 1, high: 2 }

  validates :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :target_weight, numericality: { greater_than: 0 }, allow_nil: true

  # YouTube検索条件キーを生成
  def condition_key
    return nil if gender.nil? || training_intensity.nil?
    "#{gender}_#{training_intensity}"  # 例: "man_low"
  end
end
```

**主要な機能:**
- ユーザーのプロフィール情報
- enumによる性別・トレーニング強度の管理
- `condition_key`でYouTube動画の検索条件を生成

#### 4.2.2 コントローラー層（Controllers）

**BodyRecordsController** (`app/controllers/body_records_controller.rb`)
- **役割**: 身体情報の記録（CRUD操作）
- **主要なアクション**:
  - `top`: カレンダー表示（月別の記録一覧）
  - `new`: 新規記録フォーム
  - `create`: 記録の保存
  - `edit`/`update`: 記録の編集

**ProgressController** (`app/controllers/progress_controller.rb`)
- **役割**: グラフ・写真の経過表示
- **主要なアクション**:
  - `index`: グラフ・統計表・写真を表示
- **使用するService**:
  - `ProgressDataService`: グラフ用データの集計
  - `BodyRecordPhotoService`: 写真データの取得

**RecommendedVideosController** (`app/controllers/recommended_videos_controller.rb`)
- **役割**: YouTube動画のレコメンド
- **主要なアクション**:
  - `index`: おすすめ動画一覧
  - `refresh`: YouTube APIから動画を再取得
- **使用するService**:
  - `RecommendedVideoService`: 動画の取得・キャッシュ管理
  - `YoutubeService`: YouTube API呼び出し

**ProfilesController** (`app/controllers/profiles_controller.rb`)
- **役割**: プロフィール管理
- **主要なアクション**:
  - `show`: プロフィール表示
  - `edit`/`update`: プロフィール編集

**FavoriteVideosController** (`app/controllers/favorite_videos_controller.rb`)
- **役割**: お気に入り動画の追加・削除
- **主要なアクション**:
  - `create`: お気に入りに追加
  - `destroy`: お気に入りから削除
- **使用するService**:
  - `FavoriteVideoService`: YouTube URLから動画情報を取得

**LineBotController** (`app/controllers/line_bot_controller.rb`)
- **役割**: LINE Botからのリクエスト処理
- **主要なアクション**:
  - `callback`: LINE Webhookの受信
- **使用するService**:
  - `LineBotService`: LINE APIへのメッセージ送信

#### 4.2.3 サービス層（Services）

Service Objectパターンにより、コントローラーとモデルからビジネスロジックを分離しています。

**ProgressDataService** (`app/services/progress_data_service.rb`)
```ruby
class ProgressDataService
  def initialize(user, period = "3m")
    @user = user
    @period = period
  end

  def call
    {
      dates: date_labels,
      weight_values: weight_data,
      fat_values: fat_data,
      target_weight: @user.profile&.target_weight,
      first_weight: first_record&.weight,
      last_weight: last_record&.weight,
      # ... 統計データ
    }
  end

  private

  def records_in_period
    # 期間内のbody_recordsを取得
  end
end
```

**役割**: Progressページのグラフ・統計データを集計

---

**YoutubeService** (`app/services/youtube_service.rb`)
```ruby
class YoutubeService
  BASE_URL = "https://www.googleapis.com/youtube/v3/search"

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
  end

  def fetch_videos(gender:, intensity:, target_count: 5, max_results: 40)
    # YouTube Data API から動画を検索
    # ページネーション対応
    # 重複除去
  end

  private

  def build_query(gender, intensity)
    key = "#{gender}_#{intensity}"
    KEYWORDS[:gender_intensity][key] || "workout training"
  end
end
```

**役割**: YouTube Data APIからの動画検索

**主要な機能:**
- 性別×トレーニング強度に基づいた検索キーワード
- ページネーション（複数ページから動画を取得）
- エラーハンドリング（API障害時はフォールバック）

---

**RecommendedVideoService** (`app/services/recommended_video_service.rb`)
```ruby
class RecommendedVideoService
  CACHE_EXPIRY_HOURS = 24  # キャッシュ有効期限

  def initialize(user)
    @user = user
  end

  def fetch_videos(force_refresh: false)
    condition_key = @user.profile&.condition_key
    return [] if condition_key.nil?

    if force_refresh || cache_expired?(condition_key)
      refresh_from_api(condition_key)
    else
      fetch_from_cache(condition_key)
    end
  end

  private

  def refresh_from_api(condition_key)
    # YoutubeServiceを使ってAPIから取得
    # recommended_videosテーブルに保存
  end
end
```

**役割**: YouTube動画のキャッシュ管理

**主要な機能:**
- 24時間のキャッシュ有効期限
- 手動更新（`force_refresh`）
- APIクォータ節約

#### 4.2.4 ビュー層（Views）

**パーシャルの活用** (`app/views/progress/`)
- `_graph_view.html.erb`: グラフ表示部分
- `_photo_view.html.erb`: 写真表示部分
- `_stats_table.html.erb`: 統計表部分

これらのパーシャルを`index.html.erb`で読み込み、コードの重複を削減しています。

**Stimulusコントローラーとの連携**
```erb
<div data-controller="progress"
     data-progress-labels-value='<%= @dates.to_json %>'
     data-progress-weights-value='<%= @weight_values.to_json %>'>
  <!-- Chart.jsでグラフを描画 -->
</div>
```

#### 4.2.5 JavaScriptクラス（Classes）

**ChartConfig** (`app/javascript/classes/chart_config.js`)
```javascript
export class ChartConfig {
  constructor(isMobile = false) {
    this.isMobile = isMobile;
  }

  getChartConfig(labels, weights, fats, wMin, wMax, fMin, fMax, targetWeight) {
    return {
      type: "line",
      data: {
        labels,
        datasets: this.#buildDatasets(weights, fats)
      },
      options: this.#buildOptions(wMin, wMax, fMin, fMax, targetWeight)
    };
  }
}
```

**役割**: Chart.jsの設定を管理

---

**ProgressGraph** (`app/javascript/classes/progress_graph.js`)
```javascript
export class ProgressGraph {
  constructor(graphViewElement) {
    this.graphView = graphViewElement;
    this.chart = null;
  }

  render(period = "3m") {
    // グラフを描画
  }

  destroy() {
    // メモリリーク防止のため破棄
  }
}
```

**役割**: グラフの描画・破棄

---

**ProgressStats** (`app/javascript/classes/progress_stats.js`)
```javascript
export class ProgressStats {
  constructor(graphViewElement, statsTableElement) {
    this.graphView = graphViewElement;
    this.statsTable = statsTableElement;
  }

  update(period = "3m") {
    // 統計表を更新
  }
}
```

**役割**: 統計表の更新

### 4.3 データフロー例

#### 4.3.1 身体情報の記録（BodyRecords）

```
ユーザー → 入力フォーム
           ↓
      BodyRecordsController#create
           ↓
      BodyRecord.create (バリデーション)
           ↓
      Active Storage (写真アップロード)
           ↓
      データベース保存
           ↓
      リダイレクト (カレンダーページへ)
```

#### 4.3.2 グラフ表示（Progress）

```
ユーザー → /progress アクセス
           ↓
      ProgressController#index
           ↓
      ProgressDataService.call
           ↓
      body_records から期間内のデータを集計
           ↓
      @dates, @weight_values, @fat_values を生成
           ↓
      ビューにデータを渡す
           ↓
      JavaScript (ProgressGraph) がChart.jsで描画
```

#### 4.3.3 YouTube動画レコメンド

```
ユーザー → /recommended_videos アクセス
           ↓
      RecommendedVideosController#index
           ↓
      RecommendedVideoService.fetch_videos
           ↓
      ┌─ キャッシュ有効？
      │  ├─ YES → recommended_videos テーブルから取得
      │  └─ NO  → YoutubeService.fetch_videos
      │             ↓
      │         YouTube Data API 呼び出し
      │             ↓
      │         recommended_videos テーブルに保存
      └─ 動画一覧を返す
           ↓
      ビューに表示
```

### 4.4 コードの品質管理

#### 4.4.1 テスト戦略

**テストの種類:**
- **モデルテスト**: バリデーション、アソシエーションの検証
- **サービステスト**: ビジネスロジックの単体テスト
- **システムテスト**: ユーザーの操作フローをCapybaraで検証

**テスト実行:**
```bash
# 全テスト実行
bundle exec rspec

# 特定のテストのみ
bundle exec rspec spec/models/user_spec.rb
```

**カバレッジ目標:**
- モデル: 90%以上
- サービス: 90%以上
- コントローラー: 80%以上

#### 4.4.2 静的解析（RuboCop）

```bash
# コード品質チェック
bundle exec rubocop

# 自動修正
bundle exec rubocop -a
```

**設定ファイル**: `.rubocop.yml`
- Rails標準スタイルガイドに準拠
- チーム独自のルール追加

#### 4.4.3 CI/CD（GitHub Actions）

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
      - name: Install dependencies
        run: bundle install
      - name: Run tests
        run: bundle exec rspec
      - name: Run RuboCop
        run: bundle exec rubocop
```

**自動化:**
- プッシュ時に自動テスト
- RuboCopによるコード品質チェック
- テスト失敗時はマージをブロック

### 4.5 主要な技術的工夫

#### 4.5.1 パフォーマンス最適化

**N+1問題の回避**
```ruby
# ❌ 悪い例: N+1問題
@body_records = BodyRecord.where(user_id: current_user.id)
@body_records.each do |record|
  record.photo.attached?  # 毎回SQLクエリが発生
end

# ✅ 良い例: eager loading
@body_records = BodyRecord.where(user_id: current_user.id)
                          .includes(:photo_attachment)
```

**画像の最適化**
```ruby
# Active Storageのvariant機能
photo.variant(resize_to_limit: [400, 600], quality: 70, format: :jpeg)
```

**APIキャッシュ**
- YouTube動画情報を`recommended_videos`テーブルにキャッシュ
- 24時間の有効期限で、APIクォータを節約

#### 4.5.2 セキュリティ対策

**環境変数による機密情報管理**
```ruby
# .env (Gitにコミットしない)
YOUTUBE_API_KEY=xxxxx
GOOGLE_OAUTH_CLIENT_ID=xxxxx
LINE_CHANNEL_SECRET=xxxxx

# config/initializers/devise.rb
config.omniauth :google_oauth2,
                ENV['GOOGLE_OAUTH_CLIENT_ID'],
                ENV['GOOGLE_OAUTH_CLIENT_SECRET']
```

**CSRF保護**
```ruby
# application_controller.rb
protect_from_forgery with: :exception
```

**パスワードの暗号化**
- bcryptによるハッシュ化（コストファクター12）
- Deviseが自動で処理

#### 4.5.3 エラーハンドリング

**YouTube API障害時のフォールバック**
```ruby
def fetch_videos(gender:, intensity:, target_count: 5)
  # API呼び出し
rescue StandardError => e
  Rails.logger.error("YouTube API Error: #{e.message}")
  fallback_videos(target_count)  # 空配列を返す
end
```

**画像読み込み失敗時のプレースホルダー**
```erb
<%= image_tag(@body_record.photo || asset_path('avatar_placeholder.png')) %>
```

---

## 5. まとめ

FITGRAPHは、ダイエットのモチベーション維持と運動習慣化を支援するWebアプリケーションです。

### 5.1 技術的なハイライト

1. **Rails 7 + Hotwireによるモダンな開発**
   - Turboによる高速ページ遷移
   - Stimulusによる最小限のJavaScript制御

2. **Service Objectパターンによる保守性の向上**
   - ビジネスロジックをコントローラーから分離
   - テスト容易性の向上

3. **OAuth認証による利便性**
   - Google、LINEアカウントでログイン可能
   - 二要素認証でセキュリティ強化

4. **Chart.jsによる視覚的な経過表示**
   - 体重・体脂肪率の推移をグラフで可視化
   - 写真のレイヤー表示で身体の変化を実感

5. **YouTube API連携**
   - ユーザーのニーズに合わせた動画レコメンド
   - キャッシュによるAPIクォータ節約

### 5.2 今後の拡張可能性

- **Redis + Sidekiq**: 非同期ジョブ処理（LINE通知、動画キャッシュ更新）
- **Redisキャッシュ**: データベースクエリの削減
- **PWA対応**: オフライン機能、インストール可能なアプリ
- **多言語対応**: i18nによる国際化
- **ソーシャル機能**: フレンド機能、進捗シェア

---

このドキュメントが、FITGRAPHアプリケーションのポートフォリオプレゼンに役立つことを願っています。

作成日: 2025年10月17日
