class ProgressDataService
  def initialize(user, period)
    @user = user
    @period = period.presence || "3m"
  end

  def call
    {
      graph_records: graph_records,
      dates: graph_records.map { |r| r.recorded_at.strftime("%Y-%m-%d") },
      weight_values: graph_records.map(&:weight),
      fat_values: graph_records.map(&:body_fat),
      all_graph_records: all_graph_records,
      target_weight: @user.profile&.target_weight,
      first_record: graph_records.first,
      last_record: graph_records.last,
      body_records_with_photo: body_records_with_photo,
      all_photos: all_photos
    }
  end

  private

  def graph_records
    @graph_records ||= base_query.order(:recorded_at)
  end

  def base_query
    case @period
    when "1w" then @user.body_records.where("recorded_at >= ?", 1.week.ago)
    when "3w" then @user.body_records.where("recorded_at >= ?", 3.weeks.ago)
    when "1m" then @user.body_records.where("recorded_at >= ?", 1.month.ago)
    else # "3m"
      @user.body_records.where("recorded_at >= ?", 3.months.ago)
    end
  end

  def all_graph_records
    @user.body_records.order(:recorded_at).pluck(:recorded_at, :weight, :body_fat)
  end

  def body_records_with_photo
    @user.body_records.with_attached_photo.order(:recorded_at).select { |r| r.photo.attached? }
  end

  def all_photos
    body_records_with_photo
  end
end 