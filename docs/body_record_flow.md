# 身体情報管理機能フロー

## 1. 機能概要

毎日の体重、体脂肪率、身体の写真を記録する機能です。

### 主要な機能
- カレンダー形式での記録日選択
- 体重・体脂肪率の入力
- 身体写真のアップロード（ファイル選択 or カメラ撮影）
- 記録の新規作成・更新
- 写真の自動圧縮・リサイズ

## 2. データモデル

### BodyRecordモデル
```ruby
# app/models/body_record.rb
class BodyRecord < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  # テーブルカラム
  - user_id: ユーザーID
  - recorded_at: 記録日時（日付の00:00:00）
  - weight: 体重（0〜300kg、decimal(5,2)）
  - body_fat: 体脂肪率（0〜100%、decimal(4,1)）
  - fat_mass: 脂肪量（decimal(5,2)）
  - created_at, updated_at: タイムスタンプ

  # 関連
  - photo: 身体写真（Active Storage、has_one_attached）

  # バリデーション
  - weight: 0〜300の範囲、空白可
  - body_fat: 0〜100の範囲、空白可

  # ユニーク制約
  - user_id + recorded_at の組み合わせで一意
```

## 3. ユーザーフロー

### 3-1. 基本的な操作フロー

```
[トップ画面表示]
- カレンダー表示
- 記録済み日付に紫色の枠線表示
    ↓
[カレンダーで日付をクリック]
    ↓
[トップ画面が再読み込みされ、選択日が強調表示される]
    ↓
[「＋ 身体情報を入力・編集」ボタンをクリック]
    ↓
    ├─ 選択日に記録がない場合
    │   → [新規作成画面へ遷移]
    │
    └─ 選択日に記録がある場合
        → [編集画面へ遷移]
    ↓
[フォーム入力]
    ├─ 体重入力（小数点1桁まで、0〜300kg）
    ├─ 体脂肪率入力（小数点1桁まで、0〜100%）
    └─ 写真アップロード
        ├─ カメラ撮影（スマホのみ、「カメラ起動」ボタン）
        └─ ファイル選択（PC/スマホ、「ファイルを選択」ボタン）
    ↓
[「登録する」または「更新する」ボタンをクリック]
    ↓
[バリデーション]
    ├─ 成功 → [トップ画面へリダイレクト（成功メッセージ表示）]
    └─ 失敗 → [フォーム再表示（エラーメッセージ表示）]
```

### 3-2. 画面遷移図

```
GET /body_records/top
┌──────────────────────────────────────┐
│  カレンダー表示                      │
│  - 月単位のカレンダー                │
│  - 記録済み日付に紫色の枠線表示      │
│  - 選択中の日付を紫色で強調表示      │
│  - 「＋ 身体情報を入力・編集」ボタン  │
└──────────────────────────────────────┘
         │
         │ 日付クリック
         ↓
GET /body_records/top?start_date=YYYY-MM-DD
（topページ再読み込み、選択日付を更新）
┌──────────────────────────────────────┐
│  カレンダー表示                      │
│  - 選択した日付が強調表示される      │
│  - 「＋ 身体情報を入力・編集」ボタン  │
└──────────────────────────────────────┘
         │
         │ 「＋ 身体情報を入力・編集」ボタンクリック
         │
         ├─ 選択日に記録なし
         │    ↓
         │  GET /body_records/new?recorded_at=YYYY-MM-DD
         │  ┌──────────────────────────┐
         │  │  新規登録フォーム        │
         │  │  - 日付バッジ表示        │
         │  │  - 体重入力              │
         │  │  - 体脂肪率入力          │
         │  │  - 写真アップロード      │
         │  │  - 「登録する」ボタン    │
         │  └──────────────────────────┘
         │         │
         │         │ フォーム送信
         │         ↓
         │  POST /body_records
         │         │
         │         ├─ 成功 → top画面へリダイレクト
         │         └─ 失敗 → フォーム再表示（エラーメッセージ）
         │
         └─ 選択日に記録あり
              ↓
            GET /body_records/:id/edit
            ┌──────────────────────────┐
            │  編集フォーム            │
            │  - 日付バッジ表示        │
            │  - 既存データ表示        │
            │  - 写真プレビュー表示    │
            │  - 写真削除ボタン（×）  │
            │  - 「更新する」ボタン    │
            └──────────────────────────┘
                   │
                   │ フォーム送信
                   ↓
            PATCH /body_records/:id
                   │
                   ├─ 成功 → top画面へリダイレクト
                   └─ 失敗 → フォーム再表示（エラーメッセージ）
```

## 4. 処理フロー詳細

### 4-1. トップ画面表示（top アクション）

```
GET /body_records/top?start_date=YYYY-MM-DD

1. パラメータから日付を取得（デフォルト: 今日）
   @selected_date = (params[:start_date] || params[:selected_date] || Date.current).to_date

2. カレンダー表示範囲を計算（①表示用レンジ）
   - 選択月の1日の週の日曜日 〜 月末の週の土曜日
   - すべてDateオブジェクト
   @date_range = @selected_date.beginning_of_month.beginning_of_week(:sunday) ..
                 @selected_date.end_of_month.end_of_week(:sunday)

3. DB検索用の時刻範囲を作成（②DB検索用レンジ）
   - 端をJSTの0:00 / 23:59にしたTimeレンジ
   time_range = @date_range.first.beginning_of_day ..
                @date_range.last.end_of_day

4. カレンダー表示用の記録を取得
   @body_records = current_user.body_records.where(recorded_at: time_range)
   @days_with_records = @body_records.pluck(:recorded_at).map(&:to_date)

5. 選択日の1件を取得または初期化（new兼edit）
   - 記録がある → 既存レコード取得（editに使用）
   - 記録がない → 新規レコード初期化（newに使用）
   @body_record = current_user.body_records
                   .where(recorded_at: @selected_date.all_day).first ||
                 current_user.body_records.new(recorded_at: @selected_date)

6. ビュー表示
   - カレンダー表示（Turbo Frame）
   - 記録済み日付に紫色の枠線表示
   - 選択日が強調表示
   - 「＋ 身体情報を入力・編集」ボタン表示
```

### 4-2. 新規作成フロー

```
[新規作成画面表示]
GET /body_records/new?recorded_at=YYYY-MM-DD

1. recorded_at パラメータを解析
   - 有効な日付 → その日付を使用
   - 無効/なし → 今日の日付を使用

2. 新規レコードを初期化
   @body_record = current_user.body_records.new(recorded_at: parsed_date)

3. フォーム表示
   - 日付バッジ表示（編集不可）
   - 体重入力フィールド
   - 体脂肪率入力フィールド
   - 写真アップロード UI

[フォーム送信]
POST /body_records

1. パラメータから日付を取得
   date = Date.parse(params[:body_record][:recorded_at])
   recorded_at = date.beginning_of_day (00:00:00)

2. 既存レコードを検索または初期化
   @body_record = current_user.body_records.find_or_initialize_by(
     recorded_at: recorded_at
   )
   ※同日の記録がある場合は更新、なければ新規作成

3. 属性を更新（写真以外）
   @body_record.assign_attributes(body_record_params.except(:photo))

4. 写真がアップロードされている場合
   if params[:body_record][:photo].present?
     BodyRecordPhotoService.new(@body_record).attach_processed_photo(params[:body_record][:photo])
   end

5. 保存
   成功 → トップ画面へリダイレクト（成功メッセージ）
   失敗 → フォーム再表示（エラーメッセージ）
```

### 4-3. 更新フロー

```
[編集画面表示]
GET /body_records/:id/edit

1. レコード取得
   @body_record = current_user.body_records.find(params[:id])

2. フォーム表示
   - 既存データを入力フィールドに表示
   - 写真がある場合はプレビュー表示
   - 写真削除ボタン表示

[フォーム送信]
PATCH /body_records/:id

1. レコード取得
   @body_record = current_user.body_records.find(params[:id])

2. 属性を更新（写真以外）
   @body_record.update(body_record_params.except(:photo))

3. 写真の処理
   ├─ 削除フラグがON
   │    → @body_record.photo.purge
   │
   └─ 新しい写真がアップロードされている
        → BodyRecordPhotoService.new(@body_record).attach_processed_photo(params[:body_record][:photo])

4. 保存結果
   成功 → トップ画面へリダイレクト（成功メッセージ）
   失敗 → フォーム再表示（エラーメッセージ）
```

## 5. 写真アップロード機能

### 5-1. アップロード方法

ユーザーには2つの方法が提供されています：

```
写真アップロード
    ├─ 1. カメラ撮影（スマホのみ）
    │    - 「カメラ起動」ボタンをクリック
    │    - ネイティブカメラアプリ起動
    │    - 撮影 → 自動的にフォームに設定
    │
    └─ 2. ファイル選択（PC/スマホ共通）
         - 「ファイルを選択」ボタンをクリック
         - ファイル選択ダイアログ表示
         - 画像ファイル選択 → フォームに設定
```

### 5-2. フロントエンド処理（Stimulus Controller）

```javascript
// app/javascript/controllers/camera_controller.js

[カメラ起動ボタンクリック]
    ↓
openNativeCamera()
    ↓
隠しファイル入力要素をクリック
    ↓
ネイティブカメラ起動（capture="environment" 属性）
    ↓
撮影完了
    ↓
プレビュー表示

[ファイル選択]
    ↓
ファイル選択ダイアログ
    ↓
画像選択
    ↓
プレビュー表示

[既存画像削除ボタンクリック]
    ↓
removeExistingImage()
    ↓
プレビュー画像を非表示
    ↓
hidden field に削除フラグ設定（remove_photo=1）
```

### 5-3. バックエンド処理（写真の圧縮・保存）

```
POST/PATCH body_records

params[:body_record][:photo] が存在する場合
    ↓
BodyRecordPhotoService.new(@body_record).attach_processed_photo(params[:body_record][:photo])
    ↓
ImageProcessing::MiniMagick を使用して画像処理
    ├─ リサイズ: 600x600px（アスペクト比維持）
    ├─ 品質: 60%
    └─ ファイルサイズが1MB超の場合
         → さらに品質を50%に下げる
    ↓
処理が成功
    ↓
Active Storage に添付
    @body_record.photo.attach(
      io: processed,
      filename: original_filename,
      content_type: content_type
    )
    ↓
エラーが発生した場合
    ↓
元の画像をそのまま添付
    @body_record.photo.attach(photo_param)
```

### 5-4. 写真削除フロー

```
[編集画面で削除ボタンクリック]
    ↓
フロントエンド
    - プレビュー画像を非表示
    - hidden_field に remove_photo=1 を設定
    ↓
[フォーム送信]
PATCH /body_records/:id
    ↓
バックエンド（update アクション）
    ↓
params[:remove_photo] == "1" をチェック
    ↓
@body_record.photo.purge
    ↓
Active Storage から画像を完全に削除
```

## 6. データフロー

### 6-1. 記録作成時のデータフロー

```
[ユーザー入力]
- recorded_at: "2025-01-13"
- weight: "70.5"
- body_fat: "18.5"
- photo: (ファイルオブジェクト)

    ↓

[Controller: create アクション]
1. 日付をパース
   recorded_at = Date.parse("2025-01-13").beginning_of_day
   → 2025-01-13 00:00:00 JST

2. find_or_initialize_by で同日の記録を探す
   - 存在する → 既存レコード取得
   - 存在しない → 新規レコード作成

3. 属性を設定
   weight: 70.5
   body_fat: 18.5

4. 写真処理（BodyRecordPhotoService）
   photo → 圧縮・リサイズ → Active Storage

    ↓

[Database]
body_records テーブルにINSERT/UPDATE
  - id: (自動採番)
  - user_id: current_user.id
  - recorded_at: 2025-01-13 00:00:00
  - weight: 70.5
  - body_fat: 18.5
  - fat_mass: (未計算の場合 null)
  - created_at: (現在時刻)
  - updated_at: (現在時刻)

active_storage_blobs テーブルに写真情報を保存
active_storage_attachments テーブルに関連付けを保存

    ↓

[レスポンス]
成功: トップ画面へリダイレクト（flash メッセージ）
失敗: フォーム再表示（エラーメッセージ）
```

### 6-2. 記録取得時のデータフロー

```
[Request]
GET /body_records/top?start_date=2025-01-13

    ↓

[Controller: top アクション]
1. 日付範囲を計算
   例: 2025-01-13を選択した場合
   @date_range = 2024-12-29 (日) 〜 2025-02-01 (土)
   （1月の1日を含む週の日曜日 〜 1月の末日を含む週の土曜日）

2. DB検索用の時刻範囲
   time_range = 2024-12-29 00:00:00 〜 2025-02-01 23:59:59

3. SQL発行
   SELECT * FROM body_records
   WHERE user_id = ?
     AND recorded_at BETWEEN ? AND ?
   ORDER BY recorded_at

    ↓

[Database]
該当する body_records を取得
- Active Storage の関連も含む（N+1 問題に注意）

    ↓

[View]
- カレンダー表示
  - @body_records をループ
  - 記録がある日付に印を表示
- 選択日の記録があれば編集フォーム表示
- なければ新規作成フォーム表示
```

## 7. ルーティング

```ruby
# config/routes.rb
authenticated :user do
  root "body_records#top", as: :authenticated_root
end

resources :body_records, only: %i[new create show edit update] do
  collection do
    get :top
  end
end
```

### ルート一覧

| HTTP Method | Path | Controller#Action | 用途 |
|------------|------|-------------------|------|
| GET | /body_records/top | body_records#top | カレンダー表示 |
| GET | /body_records/new | body_records#new | 新規作成フォーム |
| POST | /body_records | body_records#create | 記録作成 |
| GET | /body_records/:id/edit | body_records#edit | 編集フォーム |
| PATCH | /body_records/:id | body_records#update | 記録更新 |

※ `show`アクションはルーティングに定義されていますが、コントローラーには実装されていません

## 8. 主要なファイル構成

```
app/
├── models/
│   └── body_record.rb              # モデル定義、バリデーション
├── controllers/
│   └── body_records_controller.rb  # アクション定義、処理フロー
├── services/
│   └── body_record_photo_service.rb # 写真圧縮・リサイズ処理
├── views/
│   └── body_records/
│       ├── top.html.erb            # カレンダー表示
│       ├── new.html.erb            # 新規作成フォーム
│       ├── edit.html.erb           # 編集フォーム
│       └── _form.html.erb          # フォーム部品（共通）
└── javascript/
    └── controllers/
        └── camera_controller.js    # 写真撮影・プレビュー処理

db/
└── migrate/
    └── YYYYMMDDHHMMSS_create_body_records.rb  # テーブル定義
```

## 9. セキュリティ考慮事項

### 認証・認可
- `before_action :authenticate_user!` で全アクションに認証必須
- `current_user.body_records` でスコープを制限、他ユーザーの記録にはアクセス不可

### バリデーション
- 体重: 0〜300kg の範囲チェック
- 体脂肪率: 0〜100% の範囲チェック
- recorded_at: user_id との組み合わせで一意制約（DB レベル）

### ファイルアップロード
- `accept: "image/*"` で画像ファイルのみ許可（フロントエンド）
- ImageProcessing でリサイズ・圧縮（600x600px、品質60%）
- エラーハンドリングで悪意ある画像への対策

### ストロングパラメータ
```ruby
params.require(:body_record).permit(
  :recorded_at, :weight, :body_fat, :fat_mass, :photo
)
```

## 10. パフォーマンス最適化

### データベース
- `user_id + recorded_at` にユニークインデックス
- where 句での範囲検索に対応

### 画像処理
- アップロード時に自動圧縮（600x600px、品質60%）
- 1MB超の場合さらに品質を50%に下げる
- 表示時にもバリアント生成（300x450px、品質70%）

### フロントエンド
- Turbo Frame でカレンダー部分のみ更新
- プレビュー表示で UX 向上

## 11. 今後の拡張可能性

### 実装候補
- 脂肪量の自動計算（体重 × 体脂肪率）
- グラフ表示（体重・体脂肪率の推移）
- 記録削除機能
- データエクスポート機能
- 複数枚の写真アップロード
- 写真の比較表示機能

### 技術的改善
- N+1 問題の解決（includes :photo）
- キャッシュ戦略の導入
- 非同期画像処理（Active Job）
- CDN による画像配信

## 12. 実装のポイント

### 12-1. シンプルカレンダー

#### シンプルカレンダーとは？

`simple_calendar` は、Railsアプリケーションで簡単にカレンダー表示を実装できるgemです。月単位、週単位のカレンダーを簡単に生成できます。

#### 実装手順

**1. Gemのインストール**

```ruby
# Gemfile
gem "simple_calendar", "~>2.0"
```

**2. コントローラーでの実装**

```ruby
# app/controllers/body_records_controller.rb
def top
  @selected_date = (params[:start_date] || params[:selected_date] || Date.current).to_date

  # ① 表示用レンジ ― すべて Date オブジェクト
  @date_range = (
    @selected_date.beginning_of_month.beginning_of_week(:sunday) ..
    @selected_date.end_of_month.end_of_week(:sunday)
  )

  # ② DB 検索用レンジ ― 端を JST の 0:00 / 23:59 にした Time レンジ
  time_range = @date_range.first.beginning_of_day ..
               @date_range.last.end_of_day

  # カレンダー表示用の記録を取得
  @body_records = current_user.body_records.where(recorded_at: time_range)
  @days_with_records = @body_records.pluck(:recorded_at).map(&:to_date)

  # 選択日の 1 件 (new 兼 edit)
  @body_record = current_user.body_records
                  .where(recorded_at: @selected_date.all_day).first ||
                current_user.body_records.new(recorded_at: @selected_date)
end
```

**3. ビューでの実装**

```erb
<!-- app/views/body_records/top.html.erb -->
<%= turbo_frame_tag "calendar" do %>
  <%= month_calendar(events: @body_records, attribute: :recorded_at) do |date, body_records| %>
    <%= link_to date.day, top_body_records_path(start_date: date) %>
  <% end %>
<% end %>
```


**4. カスタムビューの作成**

```erb
<!-- app/views/simple_calendar/_month_calendar.html.erb -->
<table class="w-full">
  <thead>
    <tr>
      <% @date_range.first(7).each do |day| %>
        <th><%= t('date.abbr_day_names')[day.wday] %></th>
      <% end %>
    </tr>
  </thead>
  <tbody>
    <% @date_range.each_slice(7) do |week| %>
      <tr>
        <% week.each do |day| %>
          <% has_record = @days_with_records.include?(day) %>
          <td>
            <%= link_to day.day, top_body_records_path(start_date: day) %>
          </td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```

#### 工夫した点

1. **Turbo Frameによる部分更新**
   - カレンダー部分のみを更新することで、ページ全体のリロードを避け、UXを向上

2. **日付範囲の計算の分離**
   ```ruby
   # ① 表示用レンジ ― すべて Date オブジェクト
   @date_range = @selected_date.beginning_of_month.beginning_of_week(:sunday) ..
                 @selected_date.end_of_month.end_of_week(:sunday)

   # ② DB 検索用レンジ ― 端を JST の 0:00 / 23:59 にした Time レンジ
   time_range = @date_range.first.beginning_of_day ..
                @date_range.last.end_of_day
   ```
   - 表示用とDB検索用で範囲を分けて管理
   - 月の最初と最後を含む週全体を表示（日曜始まり）
   - カレンダーの見た目が自然になる

3. **選択日の記録を事前取得**
   ```ruby
   @body_record = current_user.body_records
                   .where(recorded_at: @selected_date.all_day).first ||
                 current_user.body_records.new(recorded_at: @selected_date)
   ```
   - topページで選択日の記録を取得または初期化
   - カレンダーの「＋ 身体情報を入力・編集」ボタンから、既存レコードの有無に応じてedit/newへ遷移可能
   - シームレスなUXを実現

4. **記録済み日付の強調表示**
   - `@days_with_records`配列で記録がある日付を管理
   - 紫色の枠線で記録済み日付を視覚的に識別可能

5. **選択日の強調表示**
   - 選択中の日付を紫色の背景で表示
   - ユーザーが現在どの日付を見ているかが明確

6. **今日の日付の特別表示**
   - 今日の日付を薄い紫色の背景で表示
   - 時間軸の把握がしやすい

7. **複数のパラメータに対応**
   ```ruby
   @selected_date = (params[:start_date] || params[:selected_date] || Date.current).to_date
   ```
   - `start_date`と`selected_date`の両方のパラメータに対応
   - リダイレクト時の柔軟性が向上

### 12-2. Active Storage

#### Active Storageとは？

Active StorageはRailsに標準で組み込まれているファイルアップロード機能です。クラウドストレージ（AWS S3, Google Cloud Storage等）やローカルストレージに簡単にファイルを保存できます。

#### 実装手順

**1. インストール**

```bash
rails active_storage:install
rails db:migrate
```

これにより以下のテーブルが作成されます：
- `active_storage_blobs` - ファイルのメタデータ
- `active_storage_attachments` - モデルとファイルの関連付け
- `active_storage_variant_records` - 画像のバリアント情報

**2. モデルへの追加**

```ruby
# app/models/body_record.rb
class BodyRecord < ApplicationRecord
  has_one_attached :photo
end
```

この1行で、以下の機能が使えるようになります：

1. `body_record.photo.attach(file)` - 画像をアップロード
2. `body_record.photo.attached?` - 画像が存在するか確認
3. `body_record.photo.purge` - 画像を削除
4. `body_record.photo.url` - 画像のURLを取得

**3. フォームでの実装**

```erb
<%= form_with model: @body_record, multipart: true do |f| %>
  <%= f.file_field :photo, accept: "image/*" %>
<% end %>
```

**4. ビューでの表示**

```erb
<% if @body_record.photo.attached? %>
  <%= image_tag @body_record.photo.variant(resize_to_limit: [300, 450], quality: 70, format: :jpeg).processed %>
<% end %>
```

#### 工夫した点

1. **バリアントの活用**
   - 表示時に適切なサイズにリサイズ（300x450px）
   - 品質を70%に設定して、ファイルサイズを削減

2. **条件付き表示**
   - `photo.attached?`で画像の有無を確認
   - 画像がない場合はプレースホルダーを表示

3. **multipart対応**
   - `form_with`に`multipart: true`を指定
   - ファイルアップロードを正しく処理

4. **セキュリティ**
   - `accept: "image/*"`で画像ファイルのみ許可
   - フロントエンドでの最初のフィルタリング

### 12-3. フォーム表示

#### 実装内容

新規作成と編集で共通のフォームパーシャル（`_form.html.erb`）を使用し、DRY原則に従った実装を行いました。

**共通フォームの構造**

```erb
<!-- app/views/body_records/_form.html.erb -->
<%= form_with model: @body_record, class: "space-y-4", multipart: true do |f| %>
  <!-- 日付バッジ -->
  <p class="inline-block bg-violet-600 text-white text-xs font-medium rounded-full px-2 py-0.5">
    <%= @body_record.recorded_at.strftime("%Y年%m月%d日") %>
  </p>
  <%= f.hidden_field :recorded_at %>

  <!-- 体重 & 体脂肪率 -->
  <div class="grid grid-cols-2 gap-2">
    <div>
      <%= f.label :weight, "体重", class: "block text-violet-600 text-xs mb-0.5" %>
      <%= f.number_field :weight, step: 0.1, min: 0, class: "..." %>
      <% if @body_record.errors[:weight].present? %>
        <div class="text-xs text-red-600 mt-1">
          <%= @body_record.errors.full_messages_for(:weight).join(', ') %>
        </div>
      <% end %>
    </div>
    <!-- 体脂肪率も同様 -->
  </div>

  <!-- 写真アップロード -->
  <div data-controller="camera" class="space-y-2">
    <!-- カメラ操作ボタン -->
    <!-- プレビューエリア -->
  </div>

  <!-- 送信ボタン -->
  <%= render "shared/button",
      text: (@body_record.persisted? ? "更新する" : "登録する"),
      type: "submit" %>
<% end %>
```

#### 工夫した点

1. **パーシャルの活用**
   - `new.html.erb`と`edit.html.erb`で同じフォームを共有
   - コードの重複を避け、メンテナンス性が向上

2. **状態に応じた表示切り替え**
   ```ruby
   @body_record.persisted? ? "更新する" : "登録する"
   ```
   - 新規作成時は「登録する」、編集時は「更新する」ボタンを表示
   - ユーザーに現在の操作を明確に伝える

3. **バリデーションエラーの表示**
   - エラーがある項目のみエラーメッセージを表示
   - 赤文字で視覚的にわかりやすく表示

4. **日付の固定表示**
   - 日付はバッジとして表示し、編集不可
   - `hidden_field`でフォーム送信時に日付を含める
   - 日付の誤操作を防ぐ

5. **レスポンシブデザイン**
   - Tailwind CSSのグリッドシステムを活用
   - 体重と体脂肪率を2カラムで表示（スマホでも見やすい）

6. **小数点入力対応**
   ```erb
   <%= f.number_field :weight, step: 0.1, min: 0 %>
   ```
   - `step: 0.1`で小数点1桁まで入力可能
   - `min: 0`で負の値を防ぐ

### 12-4. Webカメラ機能

#### 実装内容

Stimulus Controllerを使用して、スマホのカメラ撮影機能を実装しました。

**Stimulus Controllerの構造**

```javascript
// app/javascript/controllers/camera_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previewContainer",
    "placeholder",
    "nativeCameraButton",
    "nativeCameraInput",
    "fileInput"
  ];

  connect() {
    // デバイス判定
    const ua = navigator.userAgent;
    const isMobile = /Mobi|Android|iPhone|iPod/.test(ua);

    if (!isMobile) {
      // PCではカメラボタンを非表示
      this.nativeCameraButtonTarget.classList.add("hidden");
    }

    // イベントリスナー設定
    this.fileInputTarget.addEventListener("change", this.previewUpload.bind(this));
    this.nativeCameraInputTarget.addEventListener("change", this.previewNativeCamera.bind(this));
  }

  openNativeCamera() {
    // ネイティブカメラを起動
    this.nativeCameraInputTarget.click();
  }

  previewNativeCamera(event) {
    const file = event.target.files[0];
    if (!file) return;

    // バリデーション
    if (file.size > 10 * 1024 * 1024) {
      alert("ファイルサイズが大きすぎます");
      return;
    }

    // プレビュー表示
    this._displayImage(file);
  }

  _displayImage(file) {
    const url = URL.createObjectURL(file);

    const img = document.createElement('img');
    img.src = url;
    img.className = 'w-full h-full object-cover rounded';

    this.previewContainerTarget.innerHTML = "";
    this.previewContainerTarget.appendChild(img);
  }

  removeExistingImage() {
    if (confirm('この画像を削除しますか？')) {
      // プレビューをクリア
      this.previewContainerTarget.innerHTML = "";

      // 削除フラグを設定
      this._addRemoveFlag();
    }
  }
}
```

**HTMLでの実装**

```erb
<div data-controller="camera">
  <!-- カメラ起動ボタン -->
  <button type="button"
          data-camera-target="nativeCameraButton"
          data-action="click->camera#openNativeCamera">
    カメラ起動
  </button>

  <!-- 隠しファイル入力（カメラ用） -->
  <%= f.file_field :photo,
        data: { camera_target: "nativeCameraInput" },
        accept: "image/*",
        capture: "environment",
        class: "hidden" %>

  <!-- ファイル選択 -->
  <%= f.file_field :photo,
        data: { camera_target: "fileInput" },
        accept: "image/*" %>

  <!-- プレビューエリア -->
  <div data-camera-target="previewContainer">
    <!-- プレビュー画像が表示される -->
  </div>
</div>
```

#### 工夫した点

1. **デバイス判定による表示切り替え**
   ```javascript
   const isMobile = /Mobi|Android|iPhone|iPod/.test(navigator.userAgent);
   if (!isMobile) {
     this.nativeCameraButtonTarget.classList.add("hidden");
   }
   ```
   - スマホではカメラ起動ボタンを表示
   - PCではカメラ起動ボタンを非表示（PCにはカメラアプリがない）
   - デバイスに応じた最適なUIを提供

2. **capture属性の活用**
   ```html
   <input type="file" accept="image/*" capture="environment">
   ```
   - `capture="environment"`で背面カメラを起動
   - スマホで直接カメラアプリが起動される

3. **リアルタイムプレビュー**
   ```javascript
   const url = URL.createObjectURL(file);
   ```
   - ファイル選択後、即座にプレビューを表示
   - サーバーへのアップロード前に確認可能
   - ユーザーが撮影結果を確認してから送信できる

4. **ファイルサイズバリデーション**
   - クライアント側で10MBの上限チェック
   - サーバーへの不要なアップロードを防ぐ
   - ユーザーに即座にフィードバック

5. **削除機能の実装**
   ```javascript
   _addRemoveFlag() {
     const removeFlag = document.createElement('input');
     removeFlag.type = 'hidden';
     removeFlag.name = 'remove_photo';
     removeFlag.value = '1';
     form.appendChild(removeFlag);
   }
   ```
   - 既存画像を削除する場合、hidden fieldで削除フラグを送信
   - サーバー側で適切に処理できるようにする

6. **Stimulus Targetsの活用**
   - 各要素に`data-camera-target`を設定
   - JavaScriptから簡単にDOM要素にアクセス可能
   - コードの可読性と保守性が向上

### 12-5. 画像の圧縮

#### 実装内容

`ImageProcessing` gemと`MiniMagick`を使用して、アップロードされた画像を自動的に圧縮・リサイズする機能を実装しました。

**サービスクラスの実装**

```ruby
# app/services/body_record_photo_service.rb
class BodyRecordPhotoService
  def initialize(body_record)
    @body_record = body_record
  end

  def attach_processed_photo(photo_param)
    begin
      # 画像を圧縮・リサイズ
      processed = ImageProcessing::MiniMagick
                    .source(photo_param.tempfile)
                    .resize_to_limit(600, 600)
                    .quality(60)
                    .call

      # ファイルサイズが1MB超の場合、さらに品質を下げる
      if processed.size > 1024 * 1024
        processed = ImageProcessing::MiniMagick
                      .source(processed)
                      .quality(50)
                      .call
      end

      # Active Storageに添付
      @body_record.photo.attach(
        io: processed,
        filename: photo_param.original_filename,
        content_type: photo_param.content_type
      )
    rescue => e
      # エラー時は元の画像をそのまま添付
      @body_record.photo.attach(photo_param)
    end
  end
end
```

**コントローラーでの使用**

```ruby
# app/controllers/body_records_controller.rb
def create
  @body_record = current_user.body_records.find_or_initialize_by(
    recorded_at: recorded_at
  )

  if params[:body_record][:photo].present?
    BodyRecordPhotoService.new(@body_record).attach_processed_photo(
      params[:body_record][:photo]
    )
  end

  @body_record.save
end
```

#### 工夫した点

1. **段階的な圧縮処理**
   ```ruby
   # 第1段階: 600x600px、品質60%
   processed = ImageProcessing::MiniMagick
                 .source(photo_param.tempfile)
                 .resize_to_limit(600, 600)
                 .quality(60)
                 .call

   # 第2段階: 1MB超なら品質50%
   if processed.size > 1024 * 1024
     processed = ImageProcessing::MiniMagick
                   .source(processed)
                   .quality(50)
                   .call
   end
   ```
   - 最初に600x600pxにリサイズし、品質60%で圧縮
   - それでも1MB超の場合、品質を50%に下げる
   - ストレージコストとユーザー体験のバランスを取る

2. **アスペクト比の維持**
   ```ruby
   .resize_to_limit(600, 600)
   ```
   - `resize_to_limit`を使用することで、アスペクト比を維持
   - 画像が歪まずに縮小される
   - 身体写真の見た目が自然に保たれる

3. **エラーハンドリング**
   ```ruby
   rescue => e
     @body_record.photo.attach(photo_param)
   end
   ```
   - 圧縮処理でエラーが発生した場合、元の画像をそのまま添付
   - 特殊な形式の画像でもアップロードが失敗しない
   - ユーザー体験を損なわない

4. **サービスクラスの分離**
   - 画像処理のロジックをサービスクラスに分離
   - コントローラーがシンプルになり、テストしやすい
   - 他の場所でも再利用可能

5. **表示時の最適化**
   ```erb
   <%= image_tag @body_record.photo.variant(
         resize_to_limit: [300, 450],
         quality: 70,
         format: :jpeg
       ).processed %>
   ```
   - 表示時にもバリアントを生成
   - 画面サイズに応じた最適なサイズで表示
   - ページの読み込み速度が向上

6. **パフォーマンスの考慮**
   - アップロード時に圧縮することで、ストレージ容量を削減
   - ネットワーク転送量を削減し、表示速度が向上
   - モバイル環境でも快適に使用可能

### 12-6. 日付の一意性制約

#### 実装内容

ユーザーが同じ日付に複数の記録を作成できないように、データベースレベルとアプリケーションレベルで一意性制約を実装しました。

**データベースレベルの制約**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_body_records.rb
create_table :body_records do |t|
  t.references :user, null: false, foreign_key: true
  t.datetime :recorded_at, null: false
  # ...
end

add_index :body_records, [:user_id, :recorded_at], unique: true
```

**アプリケーションレベルの実装**

```ruby
# app/controllers/body_records_controller.rb
def create
  date = Date.parse(body_record_params[:recorded_at])
  recorded_at = date.beginning_of_day

  # 既存のレコードを探すか、新しいレコードを作成
  @body_record = current_user.body_records.find_or_initialize_by(
    recorded_at: recorded_at
  )

  # 既存のデータを更新
  @body_record.assign_attributes(body_record_params.except(:photo))

  if @body_record.save
    redirect_to top_body_records_path,
                success: @body_record.previously_new_record? ?
                         "身体情報を登録しました" :
                         "身体情報を更新しました"
  end
end
```

#### 工夫した点

1. **find_or_initialize_byの活用**
   - 同じ日付の記録がある場合は既存レコードを取得
   - ない場合は新規レコードを初期化
   - ユーザーが意図せず重複レコードを作成することを防ぐ

2. **recorded_atの正規化**
   ```ruby
   recorded_at = date.beginning_of_day  # 00:00:00
   ```
   - 日付を常に00:00:00に正規化
   - 時刻の違いによる重複を防ぐ

3. **previously_new_record?の活用**
   ```ruby
   @body_record.previously_new_record? ?
     "身体情報を登録しました" :
     "身体情報を更新しました"
   ```
   - 新規作成か更新かを判定してメッセージを出し分け
   - ユーザーに正確なフィードバックを提供

4. **複合ユニークインデックス**
   ```ruby
   add_index :body_records, [:user_id, :recorded_at], unique: true
   ```
   - user_idとrecorded_atの組み合わせで一意性を保証
   - データベースレベルで整合性を保つ
