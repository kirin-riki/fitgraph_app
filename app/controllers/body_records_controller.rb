# app/controllers/body_records_controller.rb
class BodyRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_date, except: [:top]
  before_action :set_body_record,  only: [] # `top`アクションへの適用を解除
  before_action :set_record,       only: %i[edit update]

  def top
    @selected_date = (params[:start_date] || Date.today).to_date
    @body_record = current_user.body_records.find_or_initialize_by(recorded_at: @selected_date)
    @date_range = (@selected_date.beginning_of_month.beginning_of_week(:sunday)..
                   @selected_date.end_of_month.end_of_week(:sunday))
    @body_records = current_user.body_records.where(recorded_at: @date_range)
    @days_with_records = @body_records.pluck(:recorded_at).map(&:to_date)
    # Turbo Frame の処理は不要。top.html.erb が自動的にレンダリングされる
  end

  def new
    # recorded_at をパースし、失敗時は今日の日付を採用
    parsed_date = begin
                    Date.parse(params[:recorded_at]) if params[:recorded_at].present?
                  rescue ArgumentError, TypeError
                    nil
                  end

    @body_record = current_user.body_records.new(
      recorded_at: parsed_date || Date.today
    )
  end

  def create
    # 既存のレコードを探すか、新しいレコードを作成
    @body_record = current_user.body_records.find_or_initialize_by(
      recorded_at: body_record_params[:recorded_at]
    )

    # 既存のデータを更新
    @body_record.assign_attributes(body_record_params.except(:photo))

    if params[:body_record][:photo].present?
      attach_processed_photo(params[:body_record][:photo])
    end

    if @body_record.save
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  notice: @body_record.previously_new_record? ? "身体情報を登録しました" : "身体情報を更新しました"
    else
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
        attach_processed_photo(params[:body_record][:photo])
      end
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  notice: "身体情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def attach_processed_photo(photo_param)
    begin
      # 画像を圧縮してから添付
      processed = ImageProcessing::MiniMagick
                    .source(photo_param.tempfile)
                    .resize_to_limit(800, 800)
                    .quality(80)
                    .call

      @body_record.photo.attach(
        io: processed,
        filename: photo_param.original_filename,
        content_type: photo_param.content_type
      )
    rescue => e
      Rails.logger.error "Image processing failed: #{e.message}"
      # 画像処理に失敗した場合は、元の画像をそのまま添付
      @body_record.photo.attach(photo_param)
    end
  end

  # ① パラメータ or 今日の日付を Date オブジェクトで保持
  def set_selected_date
    @selected_date =
      begin
        Date.parse(params[:selected_date]) if params[:selected_date].present?
      rescue ArgumentError
        nil
      end || Date.today
  end

  # ② そのユーザー＆日付のレコードを 1 行用意
  def set_body_record
    @body_record =
      current_user.body_records
                  .find_or_initialize_by(recorded_at: @selected_date)
  end

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
