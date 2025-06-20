class ProgressController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = params[:period] || "3m"
    @body_records = case @period
                    when "1w"
                      current_user.body_records.where('recorded_at >= ?', 1.week.ago)
                    when "3w"
                      current_user.body_records.where('recorded_at >= ?', 3.weeks.ago)
                    when "1m"
                      current_user.body_records.where('recorded_at >= ?', 1.month.ago)
                    else # "3m"
                      current_user.body_records.where('recorded_at >= ?', 3.months.ago)
                    end
                    .with_attached_photo
                    .order(:recorded_at)
                    .select { |r| r.photo.attached? }
    @photos = @body_records.map(&:photo)

    @dates = @body_records.map { |r| r.recorded_at.strftime("%Y-%m-%d") }
    @weight_values = @body_records.map(&:weight)
    @fat_values = @body_records.map(&:body_fat)

    # 追加: 全期間分の写真データ
    @all_photos = current_user.body_records.with_attached_photo.order(:recorded_at).select { |r| r.photo.attached? }
  end
end
