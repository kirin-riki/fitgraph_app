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

    # 全期間のデータも渡す（JSで期間ごとに抽出用）
    @all_graph_records = current_user.body_records.order(:recorded_at).pluck(:recorded_at, :weight, :body_fat)

    # 目標体重を取得
    @target_weight = current_user.profile&.target_weight

    # 期間内の最初と最後の記録
    first_record = @graph_records.first
    last_record  = @graph_records.last

    @first_weight = first_record&.weight || 0
    @last_weight  = last_record&.weight  || 0
    @first_fat    = first_record&.body_fat || 0
    @last_fat     = last_record&.body_fat  || 0
    @first_fat_mass = (first_record && first_record.weight && first_record.body_fat) ? (first_record.weight * first_record.body_fat / 100.0).round(2) : 0
    @last_fat_mass  = (last_record && last_record.weight && last_record.body_fat) ? (last_record.weight * last_record.body_fat / 100.0).round(2) : 0

    # 目標体重までのカウントダウン
    if @target_weight && @last_weight && @last_weight > 0
      if @last_weight <= @target_weight
        @weight_to_goal = 0
        @goal_achieved = true
      else
        @weight_to_goal = (@last_weight - @target_weight).round(2)
        @goal_achieved = false
      end
    else
      @weight_to_goal = 0
      @goal_achieved = false
    end

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
