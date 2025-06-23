class ProgressController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = params[:period] || "3m"

    # グラフ用のデータを取得（写真の有無を問わない）
    base_query = case @period
    when "1w" then current_user.body_records.where("recorded_at >= ?", 1.week.ago)
    when "3w" then current_user.body_records.where("recorded_at >= ?", 3.weeks.ago)
    when "1m" then current_user.body_records.where("recorded_at >= ?", 1.month.ago)
    else # "3m"
                   current_user.body_records.where("recorded_at >= ?", 3.months.ago)
    end

    @graph_records = base_query.order(:recorded_at)
    @dates = @graph_records.map { |r| r.recorded_at.strftime("%Y-%m-%d") }
    @weight_values = @graph_records.map(&:weight)
    @fat_values = @graph_records.map(&:body_fat)

    # 写真ビュー用のデータを取得（写真付きのみ）
    @body_records_with_photo = current_user.body_records
                                           .with_attached_photo
                                           .order(:recorded_at)
                                           .select { |r| r.photo.attached? }
    @photos = @body_records_with_photo.map(&:photo)

    # Stimulusコントローラー用の全期間写真データ
    @all_photos = current_user.body_records
                              .with_attached_photo
                              .order(:recorded_at)
                              .select { |r| r.photo.attached? }
  end
end
