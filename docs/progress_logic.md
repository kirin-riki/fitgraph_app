# Progressのロジック仕様

## ルーティング
### 経過（グラフ・写真）
- **パス**: `/progress`
- **HTTP メソッド**: GET
- **コントローラー**: `ProgressController#index`
- **ファイル**: `config/routes.rb:55`




## モデル
### User
- **ファイル**: `app/models/user.rb`
- **関連**:
  - `has_one :profile` - プロフィール情報（目標体重などを保持）
  - `has_many :body_records` - 身体記録（体重・体脂肪率・写真）

### Profile
- **ファイル**: `app/models/profile.rb`
- **主要属性**:
  - `target_weight` (integer): 目標体重
    - バリデーション: 0より大きい整数、nilを許可
  - `height` (integer): 身長
- **関連**: `belongs_to :user`

### BodyRecord
- **ファイル**: `app/models/body_record.rb`
- **主要属性**:
  - `weight` (decimal): 体重
    - バリデーション: 0以上300以下、空白を許可
  - `body_fat` (decimal): 体脂肪率
    - バリデーション: 0以上100以下、空白を許可
  - `photo` (Active Storage): 身体写真
- **関連**: `belongs_to :user`
- **セキュリティ**:
  - `before_update :prevent_user_id_change` - user_idの変更を禁止（改ざん防止）




## コントローラー
### ProgressController
- **ファイル**: `app/controllers/progress_controller.rb`
- **認証**: `before_action :authenticate_user!` - ログインユーザーのみアクセス可能

#### indexアクション (app/controllers/progress_controller.rb:4-40)
**パラメータ**:
- `period` (string): 表示期間（デフォルト: "3m"）

**処理フロー**:
1. ProgressDataServiceを呼び出してデータ取得
2. グラフデータの設定
3. 体重・体脂肪率の変化量計算
4. 目標体重との差分計算
5. 写真データの設定

**インスタンス変数**:
- **グラフ関連**:
  - `@period`: 表示期間
  - `@graph_records`: 表示期間内の記録
  - `@dates`: グラフのX軸（日付）
  - `@weight_values`: 体重データ配列
  - `@fat_values`: 体脂肪率データ配列
  - `@all_graph_records`: 全期間の記録
  - `@target_weight`: 目標体重

- **変化量関連**:
  - `@first_weight`: 期間開始時の体重（デフォルト: 0）
  - `@last_weight`: 期間終了時の体重（デフォルト: 0）
  - `@first_fat`: 期間開始時の体脂肪率（デフォルト: 0）
  - `@last_fat`: 期間終了時の体脂肪率（デフォルト: 0）
  - `@first_fat_mass`: 期間開始時の体脂肪量（kg）
  - `@last_fat_mass`: 期間終了時の体脂肪量（kg）

- **目標達成関連**:
  - `@weight_to_goal`: 目標体重までの残り（kg）
  - `@goal_achieved`: 目標達成フラグ（true/false）

- **写真関連**:
  - `@body_records_with_photo`: 写真付き記録
  - `@photos`: 写真データ配列
  - `@all_photos`: 全期間の写真データ

**ロジック詳細**:
- 体脂肪量の計算: `体重 × 体脂肪率 / 100.0`（小数点第2位まで）
- 目標達成判定:
  - `@last_weight <= @target_weight` の場合、`@goal_achieved = true`, `@weight_to_goal = 0`
  - それ以外の場合、`@goal_achieved = false`, `@weight_to_goal = @last_weight - @target_weight`（小数点第2位まで）




## サービス
### ProgressDataService
- **ファイル**: `app/services/progress_data_service.rb`
- **役割**: ユーザーの身体記録データを期間別に取得・整形する

#### initialize (app/services/progress_data_service.rb:2-5)
**引数**:
- `user`: 対象ユーザー
- `period`: 表示期間（デフォルト: "3m"）

#### call (app/services/progress_data_service.rb:7-20)
**返り値**: ハッシュ形式でコントローラーにデータを返却
- `graph_records`: 表示期間内の記録（recorded_at順）
- `dates`: 日付配列（"YYYY-MM-DD"形式の文字列）
- `weight_values`: 体重データ配列
- `fat_values`: 体脂肪率データ配列
- `all_graph_records`: 全期間の記録（recorded_at, weight, body_fatのみ）
- `target_weight`: ユーザーの目標体重（profileから取得、nilの可能性あり）
- `first_record`: 期間内の最初の記録
- `last_record`: 期間内の最後の記録
- `body_records_with_photo`: 写真が添付されている記録のみ（recorded_at順）
- `all_photos`: 全期間の写真付き記録（body_records_with_photoと同じ）

#### 期間フィルタリング (app/services/progress_data_service.rb:28-36)
**periodパラメータ**:
- `"1w"`: 1週間前から現在まで
- `"3w"`: 3週間前から現在まで
- `"1m"`: 1ヶ月前から現在まで
- `"3m"` (その他): 3ヶ月前から現在まで（デフォルト）

## ビュー

### index.html.erb
- **ファイル**: `app/views/progress/index.html.erb`
- **Stimulus Controller**: `progress`

#### Stimulus data属性 (app/views/progress/index.html.erb:1-6)
- `data-progress-labels-value`: 日付配列のJSON（@dates）
- `data-progress-weights-value`: 体重配列のJSON（@weight_values）
- `data-progress-fat-rates-value`: 体脂肪率配列のJSON（@fat_values）
- `data-progress-target-weight-value`: 目標体重（@target_weight）、nilの場合は"null"
- `data-progress-all-records-value`: 全期間の記録のJSON（@all_graph_records）

#### レンダリング構造 (app/views/progress/index.html.erb:15-24)
1. `_graph_photo_tab.html.erb`: タブ切り替えUI
2. `_graph.html.erb`: グラフビュー
3. `_stats_table.html.erb`: 統計テーブル
4. `_photo.html.erb`: 写真ビュー（初期状態は非表示）


### _graph_photo_tab.html.erb
- **ファイル**: `app/views/progress/_graph_photo_tab.html.erb`

#### メインタブ (app/views/progress/_graph_photo_tab.html.erb:3-14)
- **グラフタブ**: 初期状態で選択（bg-violet-500）
  - `data-progress-target="tabGraph"`
- **写真タブ**: 初期状態で非選択（bg-violet-100）
  - `data-progress-target="tabPhoto"`

#### 期間タブ (app/views/progress/_graph_photo_tab.html.erb:19-34)
グラフ・写真両方で共通使用
- **3ヶ月**: 初期状態で選択、`data-period="3m"`
- **1ヶ月**: `data-period="1m"`
- **3週間**: `data-period="3w"`
- **1週間**: `data-period="1w"`

#### レイヤー/比較タブ (app/views/progress/_graph_photo_tab.html.erb:38-58)
写真タブ選択時のみ表示（初期状態は非表示）
- **レイヤータブ**: 初期状態で選択
  - `data-progress-target="layerTab"`
  - `data-action="click->progress#setPhotoSubTab"`
  - `data-tab="layer"`
- **比較タブ**: 初期状態で非選択
  - `data-progress-target="compareTab"`
  - `data-action="click->progress#setPhotoSubTab"`
  - `data-tab="compare"`


### _graph.html.erb
- **ファイル**: `app/views/progress/_graph.html.erb`

#### Chart.js用Canvas (app/views/progress/_graph.html.erb:5-7)
- `id="weightChart"`: Chart.jsで描画するcanvas要素
- `data-progress-target="weightChart"`: Stimulusターゲット


### _stats_table.html.erb
- **ファイル**: `app/views/progress/_stats_table.html.erb`
- **初期状態**: 非表示（hidden）

#### 目標達成表示 (app/views/progress/_stats_table.html.erb:3-13)
**条件分岐**:
- `@target_weight`が存在し、`@last_weight > 0`の場合のみ表示
- `@goal_achieved = false`の場合:
  - 「目標まであと」+ `@weight_to_goal` + 「kg」を表示
- `@goal_achieved = true`の場合:
  - 「目標達成！！！」を表示

#### 統計テーブル (app/views/progress/_stats_table.html.erb:15-52)
**表示項目**:
1. **体重**: `@first_weight` → `@last_weight` (kg)
2. **体脂肪率**: `@first_fat` → `@last_fat` (%)
3. **脂肪量**: `@first_fat_mass` → `@last_fat_mass` (kg)

**数値フォーマット**: `number_with_precision(値, precision: 2)` - 小数点第2位まで表示


### _photo.html.erb
- **ファイル**: `app/views/progress/_photo.html.erb`

#### レイヤービュー (app/views/progress/_photo.html.erb:2-38)
- **Stimulus Controller**: `photo-switcher`
- **data属性**:
  - `data-photos`: 全写真データのJSON配列（URLと日付）
    - 画像がある場合: variant処理（resize_to_limit: [400, 600], quality: 70, format: :jpeg）
    - 画像がない場合: プレースホルダー画像
  - `data-placeholder`: プレースホルダー画像のパス
  - `data-jst-today`: 本日の日付（YYYY-MM-DD形式）

**スライダー** (app/views/progress/_photo.html.erb:27-36):
- 写真が2枚以上ある場合のみ表示
- `min="1"`, `max="写真数"`, `value="1"`
- `data-action="input->photo-switcher#slide"`

#### 比較ビュー (app/views/progress/_photo.html.erb:40-51)
- **初期状態**: 非表示（hidden）
- **表示内容**:
  - BEFORE画像: `id="compare-before"`、初期値はプレースホルダー
  - AFTER画像: `id="compare-after"`、初期値はプレースホルダー




## JavaScript (Stimulus Controllers)
### progress_controller.js
- **ファイル**: `app/javascript/controllers/progress_controller.js`
- **ライブラリ**: Chart.js (chart.js/auto)

#### Targets (app/javascript/controllers/progress_controller.js:5-9)
- `graphView`: グラフビュー全体
- `photoView`: 写真ビュー全体
- `tabGraph`: グラフタブボタン
- `tabPhoto`: 写真タブボタン
- `weightChart`: Chart.js用canvas要素
- `statsTable`: 統計テーブル全体
- `statsContent`: 統計テーブルの内容
- `periodTab`: 期間タブボタン（複数）
- `photoSubTabs`: 写真サブタブ（レイヤー/比較）
- `layerTab`: レイヤータブボタン
- `compareTab`: 比較タブボタン
- `layerView`: レイヤービュー
- `compareView`: 比較ビュー

#### Values (app/javascript/controllers/progress_controller.js:11-17)
- `labels` (Array): 日付配列
- `weights` (Array): 体重配列
- `fatRates` (Array): 体脂肪率配列
- `targetWeight` (Number): 目標体重
- `allRecords` (Array): 全期間の記録

#### connect() (app/javascript/controllers/progress_controller.js:19-38)
初期化処理:
1. デフォルト値設定: `currentPeriod = "3m"`, `currentMainTab = "graph"`
2. タブイベント初期化: `initTabs()`, `initPeriodTabs()`
3. 統計テーブルを表示状態に
4. グラフ描画: `renderChart("3m")`
5. 統計テーブル更新: `updateStatsTable("3m")`
6. 写真サブタブ初期化: `setPhotoSubTab("layer")`（ターゲットが存在する場合）

#### renderChart(period) (app/javascript/controllers/progress_controller.js:48-170)
**処理フロー**:
1. 既存のChart.jsインスタンスを破棄
2. `buildChartData(period)`でデータ整形
3. 日付ラベル生成（M/D形式）
4. Y軸範囲計算:
   - 体重軸: 最小値-5 〜 最大値+5
   - 体脂肪率軸: 最小値-5 〜 最大値+5
   - 目標体重がデータ範囲外の場合、範囲を拡張
5. モバイル判定（window.innerWidth < 768）
6. Chart.js設定:
   - タイプ: line（折れ線グラフ）
   - データセット1: 体重（赤、左軸y1）
   - データセット2: 体脂肪率（青緑、右軸y2）
   - spanGaps: true（欠損値をスキップ）
7. カスタムプラグイン: `targetWeightMarker`
   - 目標体重の位置に紫色の円を描画
   - 水平の点線を引く

#### buildChartData(period) (app/javascript/controllers/progress_controller.js:173-204)
**処理フロー**:
1. 期間に応じた開始日を計算
2. 開始日から現在までの日付範囲を生成（1日単位）
3. `labelsValue`, `weightsValue`, `fatRatesValue`からマップ作成
4. 各日付に対して、データがあれば値を、なければnullを設定
5. 返り値: `[{label: "YYYY-MM-DD", weight: 値 or null, fat: 値 or null}, ...]`

#### updateStatsTable(period) (app/javascript/controllers/progress_controller.js:207-272)
**処理フロー**:
1. 期間に応じて`allRecordsValue`をフィルタリング
2. 有効な値（0やnullでない値）のみを抽出
3. 期間内の最初と最後の値を取得
4. 体脂肪量を計算: `体重 × 体脂肪率 / 100`（小数点第2位まで）
5. 目標達成判定: `lastWeight <= targetWeight`
6. DOM更新:
   - `first-weight`, `last-weight`, `first-fat`, `last-fat`, `first-fat-mass`, `last-fat-mass`
   - 目標達成時: 「目標達成！！！」
   - 未達成時: 「目標まであと XX.XX kg」

#### setMainTab(active) (app/javascript/controllers/progress_controller.js:280-306)
**引数**: "graph" または "photo"

**グラフタブ選択時**:
- グラフビューを表示、写真ビューを非表示
- 写真サブタブを非表示
- 統計テーブルを表示
- グラフを再描画

**写真タブ選択時**:
- 写真ビューを表示、グラフビューを非表示
- 写真サブタブを表示
- 統計テーブルを非表示

#### initPeriodTabs() (app/javascript/controllers/progress_controller.js:308-331)
期間タブのクリックイベントを設定:
1. クリックされたタブをアクティブに（紫背景）
2. `currentPeriod`を更新
3. グラフタブの場合:
   - `renderChart(period)`
   - `updateStatsTable(period)`
4. 写真タブの場合:
   - photo-switcherコントローラーの`setPeriod(period)`を呼び出し
   - `updateCompareView(period)`

#### setPhotoSubTab(event) (app/javascript/controllers/progress_controller.js:334-360)
**引数**: "layer" または "compare"

**レイヤータブ選択時**:
- レイヤービューを表示、比較ビューを非表示

**比較タブ選択時**:
- 比較ビューを表示、レイヤービューを非表示
- `updateCompareView(period)`を実行

#### updateCompareView(period) (app/javascript/controllers/progress_controller.js:362-392)
**処理フロー**:
1. photo-switcherコントローラーから全写真データを取得
2. 期間でフィルタリング
3. 日付でソート
4. BEFORE画像: 期間内の最初の写真
5. AFTER画像: 期間内の最後の写真
6. 写真がない場合: プレースホルダー画像


### photo_switcher_controller.js
- **ファイル**: `app/javascript/controllers/photo_switcher_controller.js`

#### Targets (app/javascript/controllers/photo_switcher_controller.js:4)
- `image`: 表示する画像要素
- `slider`: スライダー要素

#### connect() (app/javascript/controllers/photo_switcher_controller.js:6-19)
**処理フロー**:
1. `data-photos`属性からJSON解析して全写真データを取得
2. デフォルト期間を"3m"に設定
3. 期間ボタンのクリックイベントを設定
4. 初期期間でフィルタリング: `setPeriod("3m")`
5. 外部からアクセス可能にするため`this.element.StimulusController = this`を設定

#### setPeriod(period) (app/javascript/controllers/photo_switcher_controller.js:21-70)
**処理フロー**:
1. 期間に応じた開始日を計算
2. JST（日本標準時）の今日の日付を取得
   - `data-jst-today`属性から取得、なければUTC+9時間で計算
3. 開始日〜今日の範囲で写真をフィルタリング
4. `updateImage(0)`で最初の写真を表示
5. スライダーの設定:
   - `max = 写真枚数`
   - `value = 1`
   - 写真が1枚以下の場合はスライダーを非表示

#### slide() (app/javascript/controllers/photo_switcher_controller.js:72-76)
スライダーの値を取得して`updateImage(index)`を呼び出し

#### updateImage(index) (app/javascript/controllers/photo_switcher_controller.js:78-95)
**処理フロー**:
1. 写真が0枚の場合: プレースホルダー画像を表示
2. 写真が存在する場合: `photos[index].url`を画像srcに設定
3. URLがない場合: フォールバックとしてプレースホルダー画像

