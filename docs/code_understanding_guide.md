# FITGRAPH コード理解ガイド（初心者向け）

## はじめに

このドキュメントは、FITGRAPHアプリのコードを初めて読む方のために作成されました。
「なぜこのコードが必要なのか」「どのように動いているのか」を、できるだけわかりやすく説明します。

---

## 目次

1. [Railsアプリケーションの基本構造](#1-railsアプリケーションの基本構造)
2. [データベースとモデルの理解](#2-データベースとモデルの理解)
3. [ユーザー認証の仕組み](#3-ユーザー認証の仕組み)
4. [身体情報記録機能の実装](#4-身体情報記録機能の実装)
5. [グラフ表示機能の実装](#5-グラフ表示機能の実装)
6. [YouTube動画レコメンド機能の実装](#6-youtube動画レコメンド機能の実装)
7. [画像アップロード機能の実装](#7-画像アップロード機能の実装)
8. [LINE Bot連携機能の実装](#8-line-bot連携機能の実装)
9. [よくある質問（FAQ）](#9-よくある質問faq)

---

## 1. Railsアプリケーションの基本構造

### 1.1 MVCアーキテクチャとは？

Railsは**MVC（Model-View-Controller）**というデザインパターンを採用しています。

```
ユーザー（ブラウザ）
    ↓
[Controller] ← ルーティング(routes.rb)で振り分け
    ↓
[Model] ← データベースとのやり取り
    ↓
[View] ← HTMLを生成
    ↓
ユーザー（ブラウザ）に返す
```

#### 具体例: 身体情報の記録

1. **ユーザーがフォームを送信**
   - URL: `POST /body_records`

2. **ルーティング** (`config/routes.rb`)
   ```ruby
   resources :body_records, only: [:create]
   # これにより POST /body_records が BodyRecordsController#create に振り分けられる
   ```

3. **Controller** (`app/controllers/body_records_controller.rb`)
   ```ruby
   def create
     @body_record = current_user.body_records.build(body_record_params)
     if @body_record.save
       redirect_to top_body_records_path, notice: '記録しました'
     else
       render :new
     end
   end
   ```

4. **Model** (`app/models/body_record.rb`)
   ```ruby
   class BodyRecord < ApplicationRecord
     validates :weight, numericality: { greater_than_or_equal_to: 0 }
     # バリデーション: 体重は0以上でないとエラー
   end
   ```

5. **View** (`app/views/body_records/new.html.erb`)
   ```erb
   <%= form_with model: @body_record do |f| %>
     <%= f.number_field :weight %>
     <%= f.submit '保存' %>
   <% end %>
   ```

### 1.2 ディレクトリ構造

```
app/
├── controllers/       # ユーザーからのリクエストを処理
├── models/            # データベースとのやり取り、ビジネスルール
├── views/             # HTML生成（ERBテンプレート）
├── services/          # 複雑なビジネスロジック（Service Object）
├── javascript/        # JavaScriptコード（Stimulus、Chart.js）
└── assets/            # CSS、画像などの静的ファイル

config/
├── routes.rb          # URLとコントローラーのマッピング
├── database.yml       # データベース接続設定
└── initializers/      # 各種Gemの初期設定

db/
├── migrate/           # マイグレーションファイル（テーブル定義の履歴）
└── schema.rb          # 現在のデータベース構造

spec/                  # テストコード（RSpec）
```

### 1.3 リクエストの流れ

例: ユーザーが `/progress` にアクセスしたとき

```
1. ブラウザ → GET /progress
   ↓
2. config/routes.rb
   get "progress", to: "progress#index"
   ↓
3. app/controllers/progress_controller.rb
   def index
     @dates = [...]
     @weight_values = [...]
   end
   ↓
4. app/views/progress/index.html.erb
   <canvas id="weightChart"></canvas>
   ↓
5. app/javascript/progress_chart.js
   Chart.jsでグラフを描画
   ↓
6. ブラウザに表示
```

---

## 2. データベースとモデルの理解

### 2.1 データベースとは？

データベースは、データを整理して保存する場所です。
FITGRAPHでは**PostgreSQL**を使用しています。

#### 例: usersテーブル

| id | name | email | created_at |
|----|------|-------|------------|
| 1 | 太郎 | taro@example.com | 2025-01-01 |
| 2 | 花子 | hanako@example.com | 2025-01-02 |

### 2.2 マイグレーションファイル

**マイグレーション**は、データベースのテーブルを作成・変更する「設計図」です。

```ruby
# db/migrate/20250101000000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name, null: false        # 名前（必須）
      t.string :email, null: false       # メールアドレス（必須）
      t.timestamps                       # created_at, updated_at を自動生成
    end

    add_index :users, :email, unique: true  # emailは重複不可
  end
end
```

**実行方法:**
```bash
rails db:migrate
```

これで`schema.rb`が更新され、データベースに`users`テーブルが作成されます。

### 2.3 モデルの役割

**モデル**は、データベースのテーブルとRubyコードをつなぐ橋渡しです。

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one :profile          # 1人のユーザーは1つのプロフィールを持つ
  has_many :body_records    # 1人のユーザーは複数の身体記録を持つ

  validates :name, presence: true        # 名前は必須
  validates :email, presence: true, uniqueness: true  # メールは必須で一意
end
```

**使い方:**
```ruby
# ユーザーを作成
user = User.create(name: "太郎", email: "taro@example.com")

# ユーザーを検索
user = User.find_by(email: "taro@example.com")

# ユーザーの身体記録を取得
body_records = user.body_records  # 関連テーブルから自動取得
```

### 2.4 FITGRAPHの主要モデル

#### User（ユーザー）
```ruby
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :body_records
  has_many :favorite_videos, dependent: :destroy

  # dependent: :destroy → ユーザーを削除すると、関連データも削除される
end
```

#### Profile（プロフィール）
```ruby
class Profile < ApplicationRecord
  belongs_to :user

  enum :gender, { man: 0, woman: 1, other: 2 }
  enum :training_intensity, { low: 0, medium: 1, high: 2 }

  # enumで数値を名前で扱える
  # gender=0 → "man"
  # gender=1 → "woman"
end
```

**使い方:**
```ruby
profile = user.profile
profile.gender = :man
profile.training_intensity = :low
profile.save

profile.gender  # => "man"
profile.man?    # => true（enumの自動メソッド）
```

#### BodyRecord（身体記録）
```ruby
class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo  # Active Storageで写真を管理

  validates :weight, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 300
  }, allow_nil: true
end
```

**使い方:**
```ruby
body_record = BodyRecord.create(
  user: current_user,
  recorded_at: Date.today,
  weight: 70.5,
  body_fat: 18.2
)

# 写真を添付
body_record.photo.attach(params[:photo])

# 写真があるか確認
body_record.photo.attached?  # => true
```

---

## 3. ユーザー認証の仕組み

### 3.1 Deviseとは？

**Devise**は、Railsで最も使われる認証Gemです。
ログイン、ログアウト、パスワードリセットなどの機能を自動で提供します。

#### インストール
```ruby
# Gemfile
gem 'devise'
```

```bash
rails generate devise:install
rails generate devise User
rails db:migrate
```

これで`User`モデルに認証機能が追加されます。

### 3.2 ログイン・ログアウト

**ルーティング:**
```ruby
# config/routes.rb
devise_for :users
# これにより以下のルートが自動生成される:
# GET  /users/sign_in   → ログインページ
# POST /users/sign_in   → ログイン処理
# DELETE /users/sign_out → ログアウト
```

**ビュー:**
```erb
<!-- app/views/devise/sessions/new.html.erb -->
<%= form_with model: @user, url: user_session_path do |f| %>
  <%= f.email_field :email %>
  <%= f.password_field :password %>
  <%= f.submit 'ログイン' %>
<% end %>
```

**コントローラーで現在のユーザーを取得:**
```ruby
class BodyRecordsController < ApplicationController
  before_action :authenticate_user!  # ログインしていないとアクセス不可

  def index
    @body_records = current_user.body_records
    # current_userは Devise が自動で提供するメソッド
  end
end
```

### 3.3 OAuth認証（Google、LINE）

#### OmniAuthとは？
**OmniAuth**は、外部サービス（Google、LINEなど）のアカウントでログインできるようにするGemです。

#### 設定
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.omniauth :google_oauth2,
                  ENV['GOOGLE_OAUTH_CLIENT_ID'],
                  ENV['GOOGLE_OAUTH_CLIENT_SECRET']

  config.omniauth :line,
                  ENV['LINE_CHANNEL_ID'],
                  ENV['LINE_CHANNEL_SECRET']
end
```

#### ログインフロー
```
1. ユーザーが「Googleでログイン」ボタンをクリック
   ↓
2. Googleのログインページに移動
   ↓
3. ユーザーが承認
   ↓
4. Googleからコールバックが返される
   GET /users/auth/google_oauth2/callback
   ↓
5. OmniauthCallbacksController#google_oauth2 が実行される
   ↓
6. User.from_omniauth(auth) でユーザーを作成/取得
   ↓
7. ログイン成功
```

#### User.from_omniauthメソッド
```ruby
# app/models/user.rb
def self.from_omniauth(auth)
  # auth にはGoogleから返された情報が入っている
  # auth.info.email → メールアドレス
  # auth.info.name  → 名前
  # auth.provider   → "google_oauth2"
  # auth.uid        → GoogleのユーザーID

  email = auth.info.email || "#{auth.uid}-#{auth.provider}@example.com"
  name = auth.info.name || "#{auth.provider.capitalize}ユーザー"

  # Google認証の場合、同じメールアドレスのユーザーがいれば紐付ける
  if auth.provider.to_s == "google_oauth2"
    user = find_by(email: email)
    if user
      user.update(provider: auth.provider, uid: auth.uid)
      return user
    end
  end

  # 新規ユーザーを作成
  user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.name = name
    user.email = email
    user.password = Devise.friendly_token[0, 20]  # ランダムなパスワード
    user.password_confirmation = user.password
  end

  user
end
```

### 3.4 二要素認証（2FA）

#### 二要素認証とは？
パスワードに加えて、スマホの認証アプリ（Google Authenticatorなど）で生成されるワンタイムパスワードを入力する仕組みです。

#### 設定の流れ
```
1. ユーザーが「2FAを有効化」ボタンをクリック
   ↓
2. QRコードを生成
   ↓
3. ユーザーが認証アプリでQRコードをスキャン
   ↓
4. 認証アプリに6桁のコードが表示される
   ↓
5. ユーザーがコードを入力
   ↓
6. サーバー側で検証
   ↓
7. 2FAが有効化される
```

#### コード例
```ruby
# app/models/user.rb
def provisioning_uri(issuer: "MyApp")
  otp_provisioning_uri(email, issuer: issuer)
  # これがQRコードになる
end
```

```ruby
# app/controllers/users/two_factor_settings_controller.rb
def show
  @qr_code = RQRCode::QRCode.new(current_user.provisioning_uri)
  @svg = @qr_code.as_svg  # QRコードをSVG形式で生成
end
```

```erb
<!-- app/views/users/two_factor_settings/show.html.erb -->
<%= raw @svg %>
<%= form_with url: users_two_factor_settings_path, method: :patch do |f| %>
  <%= f.text_field :otp_attempt %>
  <%= f.submit '有効化' %>
<% end %>
```

---

## 4. 身体情報記録機能の実装

### 4.1 カレンダー表示

FITGRAPHでは、カレンダー形式で日付を選択し、その日の身体情報を記録します。

#### Simple Calendar Gem
```ruby
# Gemfile
gem 'simple_calendar', '~>2.0'
```

```erb
<!-- app/views/body_records/top.html.erb -->
<%= month_calendar events: @body_records, attribute: :recorded_at do |date, records| %>
  <div class="calendar-day">
    <%= date.day %>
    <% record = records.first %>
    <% if record %>
      <div class="weight"><%= record.weight %>kg</div>
    <% end %>
  </div>
<% end %>
```

#### コントローラー
```ruby
# app/controllers/body_records_controller.rb
def top
  start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
  end_date = start_date.end_of_month

  @body_records = current_user.body_records
                               .where(recorded_at: start_date..end_date)
end
```

### 4.2 記録フォームの実装

#### ルーティング
```ruby
# config/routes.rb
resources :body_records, only: [:new, :create, :edit, :update]
```

#### コントローラー
```ruby
# app/controllers/body_records_controller.rb
def new
  selected_date = params[:selected_date]&.to_date || Date.today
  @body_record = current_user.body_records.find_or_initialize_by(
    recorded_at: selected_date.beginning_of_day
  )
end

def create
  @body_record = current_user.body_records.new(body_record_params)

  if @body_record.save
    redirect_to top_body_records_path, notice: '記録しました'
  else
    render :new
  end
end

private

def body_record_params
  params.require(:body_record).permit(:recorded_at, :weight, :body_fat, :photo)
end
```

#### ビュー
```erb
<!-- app/views/body_records/new.html.erb -->
<%= form_with model: @body_record do |f| %>
  <!-- 日付 -->
  <%= f.date_field :recorded_at, required: true %>

  <!-- 体重 -->
  <%= f.number_field :weight, step: 0.01, placeholder: '例: 70.5' %>

  <!-- 体脂肪率 -->
  <%= f.number_field :body_fat, step: 0.1, placeholder: '例: 18.2' %>

  <!-- 写真 -->
  <%= f.file_field :photo, accept: 'image/*' %>

  <%= f.submit '保存' %>
<% end %>
```

### 4.3 バリデーション

#### モデルでの検証
```ruby
# app/models/body_record.rb
validates :weight, numericality: {
  greater_than_or_equal_to: 0,
  less_than_or_equal_to: 300
}, allow_nil: true

validates :body_fat, numericality: {
  greater_than_or_equal_to: 0,
  less_than_or_equal_to: 100
}, allow_nil: true
```

#### エラーメッセージの表示
```erb
<% if @body_record.errors.any? %>
  <ul>
    <% @body_record.errors.full_messages.each do |message| %>
      <li><%= message %></li>
    <% end %>
  </ul>
<% end %>
```

---

## 5. グラフ表示機能の実装

### 5.1 Chart.jsとは？

**Chart.js**は、JavaScriptでグラフを描画するライブラリです。

#### インストール
```bash
yarn add chart.js
```

```javascript
// app/javascript/application.js
import Chart from 'chart.js/auto';
window.Chart = Chart;
```

### 5.2 データの準備（Controller → View）

#### コントローラー
```ruby
# app/controllers/progress_controller.rb
def index
  service = ProgressDataService.new(current_user, params[:period] || "3m")
  data = service.call

  @dates = data[:dates]              # ["2025-01-01", "2025-01-02", ...]
  @weight_values = data[:weight_values]  # [70.5, 70.3, ...]
  @fat_values = data[:fat_values]        # [18.2, 18.0, ...]
  @target_weight = data[:target_weight]  # 65
end
```

#### ビュー
```erb
<!-- app/views/progress/index.html.erb -->
<div id="graph-view"
     data-controller="progress"
     data-progress-labels-value='<%= @dates.to_json %>'
     data-progress-weights-value='<%= @weight_values.to_json %>'
     data-progress-fat-rates-value='<%= @fat_values.to_json %>'
     data-progress-target-weight-value='<%= @target_weight&.to_f || "null" %>'>
  <canvas id="weightChart"></canvas>
</div>
```

### 5.3 JavaScriptでグラフを描画

#### グラフの基本
```javascript
// app/javascript/progress_chart.js
const ctx = document.getElementById('weightChart').getContext('2d');
const chart = new Chart(ctx, {
  type: 'line',  // 折れ線グラフ
  data: {
    labels: ['1月1日', '1月2日', '1月3日'],  // X軸
    datasets: [
      {
        label: '体重(kg)',
        data: [70.5, 70.3, 70.0],  // Y軸
        borderColor: 'rgba(255,99,132,0.9)',  // 線の色
        backgroundColor: 'rgba(255,99,132,0.2)',  // 塗りつぶしの色
      }
    ]
  },
  options: {
    responsive: true,  // レスポンシブ対応
    scales: {
      y: {
        beginAtZero: false  // Y軸を0から始めない
      }
    }
  }
});
```

#### FITGRAPHでの実装（クラスベース）

```javascript
// app/javascript/classes/progress_graph.js
export class ProgressGraph {
  constructor(graphViewElement) {
    this.graphView = graphViewElement;
    this.chart = null;
  }

  render(period = "3m") {
    // data属性からデータを取得
    const labels = JSON.parse(this.graphView.dataset.progressLabelsValue);
    const weights = JSON.parse(this.graphView.dataset.progressWeightsValue);
    const fats = JSON.parse(this.graphView.dataset.progressFatRatesValue);

    // 既存のチャートを破棄
    if (this.chart) {
      this.chart.destroy();
    }

    // 新しいチャートを作成
    const ctx = document.getElementById('weightChart').getContext('2d');
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: '体重(kg)',
            data: weights,
            borderColor: 'rgba(255,99,132,0.9)',
            yAxisID: 'y1'  // 左軸
          },
          {
            label: '体脂肪率(%)',
            data: fats,
            borderColor: 'rgba(75,192,192,0.7)',
            yAxisID: 'y2'  // 右軸
          }
        ]
      },
      options: {
        responsive: true,
        scales: {
          y1: {
            type: 'linear',
            position: 'left',
            title: { display: true, text: '体重' }
          },
          y2: {
            type: 'linear',
            position: 'right',
            title: { display: true, text: '体脂肪率' },
            grid: { drawOnChartArea: false }  // グリッド線を表示しない
          }
        }
      }
    });
  }

  destroy() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  }
}
```

#### 使い方
```javascript
// app/javascript/progress_chart.js
import { ProgressGraph } from './classes/progress_graph.js';

const graphView = document.getElementById('graph-view');
const progressGraph = new ProgressGraph(graphView);
progressGraph.render('3m');  // 3ヶ月分のグラフを描画
```

### 5.4 期間切り替え

#### HTML
```erb
<button data-period="1w">1週間</button>
<button data-period="1m">1ヶ月</button>
<button data-period="3m">3ヶ月</button>
```

#### JavaScript
```javascript
document.querySelectorAll('[data-period]').forEach(button => {
  button.addEventListener('click', () => {
    const period = button.dataset.period;
    progressGraph.render(period);
  });
});
```

---

## 6. YouTube動画レコメンド機能の実装

### 6.1 YouTube Data API v3

#### API Keyの取得
1. Google Cloud Consoleで新しいプロジェクトを作成
2. YouTube Data API v3を有効化
3. 認証情報でAPI Keyを作成
4. `.env`ファイルに保存
   ```
   YOUTUBE_API_KEY=your_api_key_here
   ```

#### API呼び出しの基本
```ruby
require 'net/http'
require 'json'

uri = URI('https://www.googleapis.com/youtube/v3/search')
params = {
  key: ENV['YOUTUBE_API_KEY'],
  part: 'snippet',
  q: '初心者 有酸素 トレーニング',  # 検索キーワード
  type: 'video',
  maxResults: 10
}
uri.query = URI.encode_www_form(params)

response = Net::HTTP.get_response(uri)
data = JSON.parse(response.body)

# data['items'] に動画情報が入っている
```

### 6.2 YoutubeService

#### 検索キーワードの管理
```yaml
# config/youtube_keywords.yml
default:
  gender_intensity:
    man_low: "初心者 有酸素 トレーニング ダンス 家"
    man_medium: "自重トレーニング 家"
    man_high: "HIIT トレーニング 家"
    woman_low: "初心者 有酸素 トレーニング ダンス 家 簡単"
    woman_medium: "有酸素 トレーニング ダンス 家 ハード"
    woman_high: "有酸素 自重トレーニング 家"
  fallback: "workout training"
```

#### サービスクラス
```ruby
# app/services/youtube_service.rb
class YoutubeService
  BASE_URL = "https://www.googleapis.com/youtube/v3/search"

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
  end

  def fetch_videos(gender:, intensity:, target_count: 5)
    query = build_query(gender, intensity)

    uri = URI(BASE_URL)
    params = {
      key: @api_key,
      part: 'snippet',
      q: query,
      type: 'video',
      videoDuration: 'medium',  # 中程度の長さ
      maxResults: 40
    }
    uri.query = params.to_query

    response = Net::HTTP.get(uri)
    json = JSON.parse(response)

    items = json['items'] || []
    items.first(target_count)
  rescue StandardError => e
    Rails.logger.error("YouTube API Error: #{e.message}")
    []  # エラー時は空配列
  end

  private

  def build_query(gender, intensity)
    key = "#{gender}_#{intensity}"  # 例: "man_low"
    keywords = YAML.load_file(Rails.root.join('config', 'youtube_keywords.yml'))
    keywords['default']['gender_intensity'][key] || 'workout training'
  end
end
```

### 6.3 キャッシュ戦略

#### なぜキャッシュが必要？
YouTube Data API v3には1日あたり**10,000クォータ**の制限があります。
検索1回で100クォータ消費するため、毎回APIを呼ぶとすぐに上限に達します。

#### RecommendedVideoService
```ruby
# app/services/recommended_video_service.rb
class RecommendedVideoService
  CACHE_EXPIRY_HOURS = 24

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

  def cache_expired?(condition_key)
    latest = RecommendedVideo.where(condition_key: condition_key)
                             .order(fetched_at: :desc)
                             .first
    return true if latest.nil?

    latest.fetched_at < CACHE_EXPIRY_HOURS.hours.ago
  end

  def fetch_from_cache(condition_key)
    RecommendedVideo.where(condition_key: condition_key)
                    .order(fetched_at: :desc)
                    .limit(10)
  end

  def refresh_from_api(condition_key)
    gender, intensity = condition_key.split('_')
    youtube_service = YoutubeService.new
    videos = youtube_service.fetch_videos(gender: gender, intensity: intensity)

    # 古いキャッシュを削除
    RecommendedVideo.where(condition_key: condition_key).destroy_all

    # 新しいキャッシュを保存
    videos.each do |video|
      RecommendedVideo.create(
        video_id: video.dig('id', 'videoId'),
        title: video.dig('snippet', 'title'),
        thumbnail_url: video.dig('snippet', 'thumbnails', 'medium', 'url'),
        channel_title: video.dig('snippet', 'channelTitle'),
        fetched_at: Time.current,
        condition_key: condition_key
      )
    end

    fetch_from_cache(condition_key)
  end
end
```

### 6.4 コントローラー

```ruby
# app/controllers/recommended_videos_controller.rb
class RecommendedVideosController < ApplicationController
  def index
    service = RecommendedVideoService.new(current_user)
    @videos = service.fetch_videos
  end

  def refresh
    service = RecommendedVideoService.new(current_user)
    @videos = service.fetch_videos(force_refresh: true)
    redirect_to recommended_videos_path, notice: '動画を更新しました'
  end
end
```

---

## 7. 画像アップロード機能の実装

### 7.1 Active Storageとは？

**Active Storage**は、Railsに標準で含まれる画像アップロード機能です。
ローカルストレージやAWS S3などに画像を保存できます。

#### セットアップ
```bash
rails active_storage:install
rails db:migrate
```

これで`active_storage_blobs`と`active_storage_attachments`テーブルが作成されます。

### 7.2 モデルでの設定

```ruby
# app/models/body_record.rb
class BodyRecord < ApplicationRecord
  has_one_attached :photo
end
```

### 7.3 フォームでの画像選択

```erb
<!-- app/views/body_records/new.html.erb -->
<%= form_with model: @body_record do |f| %>
  <%= f.file_field :photo, accept: 'image/*' %>
  <%= f.submit '保存' %>
<% end %>
```

### 7.4 画像の表示

#### 基本的な表示
```erb
<% if @body_record.photo.attached? %>
  <%= image_tag @body_record.photo %>
<% end %>
```

#### リサイズ（variant機能）
```erb
<%= image_tag @body_record.photo.variant(resize_to_limit: [400, 600]) %>
```

これで、画像を400x600px以内にリサイズして表示します。

### 7.5 AWS S3との連携（本番環境）

#### Gemのインストール
```ruby
# Gemfile
gem 'aws-sdk-s3', require: false
```

#### 設定
```ruby
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: ap-northeast-1
  bucket: your-bucket-name
```

```ruby
# config/environments/production.rb
config.active_storage.service = :amazon
```

---

## 8. LINE Bot連携機能の実装

### 8.1 LINE Messaging APIとは？

LINE Messaging APIを使うと、LINEアカウントから通知を送ったり、ユーザーからのメッセージに返信したりできます。

#### LINE Developersで設定
1. LINE Developersコンソールで新しいチャネルを作成
2. Messaging APIを有効化
3. チャネルシークレット、チャネルアクセストークンを取得
4. `.env`ファイルに保存
   ```
   LINE_CHANNEL_ID=your_channel_id
   LINE_CHANNEL_SECRET=your_channel_secret
   LINE_CHANNEL_TOKEN=your_channel_token
   ```

### 8.2 LineBotService

```ruby
# app/services/line_bot_service.rb
class LineBotService
  def initialize
    @client = Line::Bot::Client.new do |config|
      config.channel_id = ENV['LINE_CHANNEL_ID']
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def push_message(line_user_id, text)
    message = {
      type: 'text',
      text: text
    }
    @client.push_message(line_user_id, message)
  end
end
```

### 8.3 Webhookの受信

```ruby
# config/routes.rb
post 'line/callback' => 'line_bot#callback'
```

```ruby
# app/controllers/line_bot_controller.rb
class LineBotController < ApplicationController
  protect_from_forgery except: :callback  # CSRF保護を無効化

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    # 署名検証
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        handle_message(event)
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def handle_message(event)
    user_message = event.message['text']
    line_user_id = event['source']['userId']

    # ユーザーを検索
    user = User.find_by(line_user_id: line_user_id)
    return unless user

    # メッセージに応じて返信
    reply_text = case user_message
    when /体重/
      "今日の体重を記録してください！"
    else
      "メッセージを受け取りました"
    end

    message = {
      type: 'text',
      text: reply_text
    }
    client.reply_message(event['replyToken'], message)
  end
end
```

---

## 9. よくある質問（FAQ）

### 9.1 `current_user`はどこから来るの？

**答え:** Deviseが自動で提供するメソッドです。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Devise がこのメソッドを自動で定義する
  # current_user → ログイン中のユーザー（Userモデル）
  # user_signed_in? → ログインしているか（true/false）
end
```

### 9.2 `@`がついている変数とついていない変数の違いは？

**答え:**
- `@変数`: **インスタンス変数**。コントローラーからビューに渡される
- `変数`: **ローカル変数**。そのメソッド内でのみ使える

```ruby
def index
  @body_records = current_user.body_records  # ビューで使える
  count = @body_records.count               # このメソッド内でのみ使える
end
```

```erb
<!-- ビューで @body_records は使えるが、count は使えない -->
<% @body_records.each do |record| %>
  <%= record.weight %>
<% end %>
```

### 9.3 `<%= %>` と `<% %>` の違いは？

**答え:**
- `<%= %>`: 実行結果を**表示**する
- `<% %>`: 実行するが**表示しない**（ループや条件分岐など）

```erb
<%= "Hello" %>  <!-- "Hello" が画面に表示される -->
<% "Hello" %>   <!-- 何も表示されない -->

<% @body_records.each do |record| %>
  <%= record.weight %>  <!-- 各レコードの体重を表示 -->
<% end %>
```

### 9.4 `params`とは？

**答え:** ユーザーがフォームで入力したデータや、URLのパラメータが入っているハッシュです。

```ruby
# URL: /body_records?selected_date=2025-01-15
params[:selected_date]  # => "2025-01-15"

# フォーム送信時
# <input name="body_record[weight]" value="70.5">
params[:body_record][:weight]  # => "70.5"
```

### 9.5 `render`と`redirect_to`の違いは？

**答え:**
- `render`: テンプレートを表示（URLは変わらない）
- `redirect_to`: 別のURLにリダイレクト（ブラウザが新しいリクエストを送る）

```ruby
def create
  @body_record = current_user.body_records.new(body_record_params)
  if @body_record.save
    redirect_to top_body_records_path  # 保存成功 → カレンダーページへ
  else
    render :new  # 保存失敗 → 入力フォームを再表示（エラーメッセージ付き）
  end
end
```

### 9.6 `permit`とは？

**答え:** **Strong Parameters**というセキュリティ機能です。
ユーザーが送信したデータのうち、許可されたものだけを受け取ります。

```ruby
def body_record_params
  params.require(:body_record).permit(:recorded_at, :weight, :body_fat, :photo)
  # :recorded_at, :weight, :body_fat, :photo だけを許可
  # それ以外のパラメータは無視される（セキュリティ対策）
end
```

### 9.7 `nil`とは？

**答え:** 「値がない」ことを表す特別な値です。

```ruby
user = User.find_by(email: "not_exist@example.com")  # 見つからない
user  # => nil

user.name  # => NoMethodError (nilはnameメソッドを持たない)

# 安全な書き方
user&.name  # => nil (エラーにならない)
```

### 9.8 `&.`（ぼっち演算子）とは？

**答え:** `nil`の場合にエラーを出さず、`nil`を返す演算子です。

```ruby
user = nil
user.name   # => NoMethodError
user&.name  # => nil（エラーにならない）

@target_weight = current_user.profile&.target_weight
# current_user.profile が nil でもエラーにならない
```

### 9.9 `enum`とは？

**答え:** 数値を名前で扱えるようにする機能です。

```ruby
# app/models/profile.rb
enum :gender, { man: 0, woman: 1, other: 2 }

profile = Profile.new(gender: :man)
profile.gender  # => "man"（内部では0が保存される）

profile.man?    # => true（自動で生成されるメソッド）
profile.woman?  # => false
```

### 9.10 `JSON.parse`と`.to_json`とは？

**答え:**
- `.to_json`: RubyのデータをJSON文字列に変換
- `JSON.parse`: JSON文字列をRubyのデータに変換

```ruby
# Rubyの配列
dates = ["2025-01-01", "2025-01-02"]

# JSONに変換
json_string = dates.to_json
# => "[\"2025-01-01\",\"2025-01-02\"]"

# JSONをRubyに変換
dates_array = JSON.parse(json_string)
# => ["2025-01-01", "2025-01-02"]
```

**ビューでの使い方:**
```erb
<div data-labels='<%= @dates.to_json %>'>
```

**JavaScriptでの使い方:**
```javascript
const labels = JSON.parse(element.dataset.labels);
// ["2025-01-01", "2025-01-02"]
```

---

## 10. まとめ

このガイドでは、FITGRAPHアプリの主要な機能の実装を解説しました。

### 10.1 学習の進め方

1. **まずは動かしてみる**
   ```bash
   docker compose up
   rails server
   ```

2. **コードを読む**
   - `config/routes.rb` → どんなURLがあるか
   - コントローラー → リクエストの処理
   - モデル → データの保存・取得
   - ビュー → HTMLの生成

3. **小さな変更を加えてみる**
   - ボタンの文言を変える
   - バリデーションを追加する
   - 新しいカラムを追加する

4. **テストを書く**
   - RSpecでテストを書くと、コードの理解が深まる

### 10.2 参考リソース

- [Rails ガイド](https://railsguides.jp/)
- [Deviseドキュメント](https://github.com/heartcombo/devise)
- [Chart.jsドキュメント](https://www.chartjs.org/docs/)
- [YouTube Data API v3リファレンス](https://developers.google.com/youtube/v3)

### 10.3 さらに学ぶべきこと

- **Service Object パターン**: ビジネスロジックの分離
- **Stimulus**: Hotwireのコントローラー
- **Turbo**: ページ遷移の高速化
- **RSpec**: テストの書き方
- **Docker**: コンテナ化の理解

---

このガイドが、FITGRAPHアプリのコード理解に役立つことを願っています。

作成日: 2025年10月17日
