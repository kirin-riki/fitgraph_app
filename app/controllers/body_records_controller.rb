class BodyRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record,       only: %i[edit update]

  def top
    @selected_date = (params[:start_date] || params[:selected_date] || Date.current).to_date

    # ① 表示用レンジ ― すべて Date オブジェクト
    @date_range = (
      @selected_date.beginning_of_month.beginning_of_week(:sunday) ..
      @selected_date.end_of_month      .end_of_week(:sunday)
    )

    # ② DB 検索用レンジ ― 端を JST の 0:00 / 23:59 にした Time レンジ
    time_range = @date_range.first.beginning_of_day ..
                 @date_range.last .end_of_day

    @body_records = current_user.body_records.where(recorded_at: time_range)
    @days_with_records = @body_records.pluck(:recorded_at).map(&:to_date)

    # 選択日の 1 件 (new 兼 edit)
    @body_record = current_user.body_records
                    .where(recorded_at: @selected_date.all_day).first ||
                  current_user.body_records.new(recorded_at: @selected_date)
  end

  def new
    # recorded_at をパースし、失敗時は今日の日付を採用
    parsed_date = begin
                    Date.parse(params[:recorded_at]) if params[:recorded_at].present?
                  rescue ArgumentError, TypeError
                    nil
                  end

    @body_record = current_user.body_records.new(
      recorded_at: parsed_date || Date.current
    )
  end

  def create
    date = begin
      Date.parse(body_record_params[:recorded_at])
    rescue ArgumentError, TypeError
      Date.current
    end
    recorded_at = date.beginning_of_day

    # 既存のレコードを探すか、新しいレコードを作成
    @body_record = current_user.body_records.find_or_initialize_by(
      recorded_at: recorded_at
    )

    # 既存のデータを更新
    @body_record.assign_attributes(body_record_params.except(:photo))
    @body_record.recorded_at = recorded_at # 念のため再代入

    if params[:body_record][:photo].present?
      BodyRecordPhotoService.new(@body_record).attach_processed_photo(params[:body_record][:photo])
    end

    if @body_record.save
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  success: @body_record.previously_new_record? ? "身体情報を登録しました" : "身体情報を更新しました"
    else
      flash.now[:danger] = "身体情報の登録・更新に失敗しました"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @body_record は set_record で取得済み
  end

  def update
    if @body_record.update(body_record_params.except(:photo))
      # 画像削除フラグの処理
      if params[:remove_photo] == "1"
        @body_record.photo.purge if @body_record.photo.attached?
      elsif params[:body_record][:photo].present?
        BodyRecordPhotoService.new(@body_record).attach_processed_photo(params[:body_record][:photo])
      end
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  success: "身体情報を更新しました"
    else
      flash.now[:danger] = "身体情報の更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # id 付きアクション用
  def set_record
    @body_record = current_user.body_records.find(params[:id])
  end

  # ストロングパラメータ
  def body_record_params
    params.require(:body_record).permit(
      :recorded_at, :weight, :body_fat, :fat_mass, :photo
    )
  end
end
