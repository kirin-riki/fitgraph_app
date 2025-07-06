class BodyRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record,       only: %i[edit update]

  def top
    @selected_date = (params[:start_date] || Date.today).to_date
    @body_record = current_user.body_records.where("DATE(recorded_at) = ?", @selected_date).first ||
                   current_user.body_records.new(recorded_at: @selected_date)
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
    # recorded_atを日付（00:00:00）に揃える
    Rails.logger.info "body_record persisted?: #{@body_record.persisted?}"
    Rails.logger.info "body_record id: #{@body_record.id}"
    date = begin
      Date.parse(body_record_params[:recorded_at])
    rescue ArgumentError, TypeError
      Date.today
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
      attach_processed_photo(params[:body_record][:photo])
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
        attach_processed_photo(params[:body_record][:photo])
      end
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  success: "身体情報を更新しました"
    else
      flash.now[:danger] = "身体情報の更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def attach_processed_photo(photo_param)
    begin
      # 画像を圧縮してから添付（1MB以下を目標）
      processed = ImageProcessing::MiniMagick
                    .source(photo_param.tempfile)
                    .resize_to_limit(600, 600)
                    .quality(60)
                    .call

      # 1MBを超える場合はさらに圧縮
      if processed.size > 1024 * 1024
        processed = ImageProcessing::MiniMagick
                      .source(processed)
                      .quality(50)
                      .call
      end

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
