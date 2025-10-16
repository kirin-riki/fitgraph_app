class DateParsingService
  class << self
    # 文字列、Date、Time、DateTime から Date オブジェクトを返す
    # パース失敗時はデフォルト値を返す(デフォルトは今日の日付)
    def parse_to_date(value, default: Date.current)
      return default if value.blank?

      case value
      when Time, DateTime
        Date.new(value.year, value.month, value.day)
      when Date
        value
      when String
        Date.parse(value)
      else
        default
      end
    rescue ArgumentError, TypeError
      default
    end

    # Time の beginning_of_day を返す
    # 主に DB 検索用(recorded_at に保存する形式)
    def parse_to_beginning_of_day(value, default: Date.current)
      date = parse_to_date(value, default: default)
      date.beginning_of_day
    end

    # 日付範囲をパースして Time の範囲を返す
    # DB検索用
    def parse_date_range(start_date, end_date)
      start_time = parse_to_beginning_of_day(start_date)
      end_time = parse_to_date(end_date).end_of_day
      start_time..end_time
    end
  end
end
