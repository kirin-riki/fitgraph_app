class BodyRecordFinder
  def initialize(user)
    @user = user
  end

  # カレンダー表示用: 月のカレンダー範囲内のレコードを取得
  # @param selected_date [Date, String] 選択された日付
  # @return [Hash] { body_records: ActiveRecord::Relation, days_with_records: Array<Date>, date_range: Range }
  def find_for_calendar(selected_date)
    date = DateParsingService.parse_to_date(selected_date)

    # 月のカレンダー範囲(週の開始と終了を含む)
    date_range = (
      date.beginning_of_month.beginning_of_week(:sunday) ..
      date.end_of_month.end_of_week(:sunday)
    )

    # DB検索用のTime範囲
    time_range = date_range.first.beginning_of_day .. date_range.last.end_of_day

    body_records = @user.body_records.where(recorded_at: time_range)
    days_with_records = body_records.pluck(:recorded_at).map(&:to_date)

    {
      body_records: body_records,
      days_with_records: days_with_records,
      date_range: date_range
    }
  end

  # 特定日のレコードを取得(なければ新規作成して返す)
  # @param date [Date, String] 取得したい日付
  # @return [BodyRecord] 既存レコード or 新規インスタンス
  def find_or_build_for_date(date)
    parsed_date = DateParsingService.parse_to_date(date)
    time_range = parsed_date.all_day

    @user.body_records.where(recorded_at: time_range).first ||
      @user.body_records.new(recorded_at: parsed_date)
  end

  # 特定日のレコードをfind_or_initialize_by (保存前の状態)
  # @param date [Date, String] 取得したい日付
  # @return [BodyRecord] 既存レコード or 新規インスタンス(未保存)
  def find_or_initialize_for_date(date)
    recorded_at = DateParsingService.parse_to_beginning_of_day(date)
    @user.body_records.find_or_initialize_by(recorded_at: recorded_at)
  end
end
