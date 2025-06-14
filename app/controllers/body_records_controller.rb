# app/controllers/body_records_controller.rb
class BodyRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_date             # ① URL から日付を読み取る
  before_action :set_body_record,  only: :top  # ② 該当レコードを 1 行取得
  before_action :set_record,       only: %i[edit update]

  def top
    @selected_date = Date.parse(params[:selected_date]) rescue Date.today

    @date_range = (@selected_date.beginning_of_month.beginning_of_week(:sunday)..
                   @selected_date.end_of_month.end_of_week(:sunday))

    @days_with_records =
      current_user.body_records
                  .where(recorded_at: @date_range)
                  .pluck(:recorded_at)
                  .map(&:to_date)
  end

  def new
    @body_record = current_user.body_records.new(recorded_at: Date.parse(params[:recorded_at]))
  end


  def create
    @body_record = current_user.body_records.new(body_record_params)
    if @body_record.save
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  notice: "身体情報を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @body_record.update(body_record_params)
      redirect_to top_body_records_path(selected_date: @body_record.recorded_at),
                  notice: "身体情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

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

  def body_record_params
    params.require(:body_record).permit(:recorded_at, :weight, :body_fat, :fat_mass, :photo)
  end
end
