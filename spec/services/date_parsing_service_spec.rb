require 'rails_helper'

RSpec.describe DateParsingService do
  describe '.parse_to_date' do
    context '正常系' do
      it 'Date オブジェクトをそのまま返す' do
        date = Date.new(2025, 1, 15)
        expect(described_class.parse_to_date(date)).to eq(date)
      end

      it 'Time オブジェクトを Date に変換する' do
        time = Time.zone.parse('2025-01-15 10:30:00')
        expect(described_class.parse_to_date(time)).to eq(Date.new(2025, 1, 15))
      end

      it 'DateTime オブジェクトを Date に変換する' do
        datetime = DateTime.new(2025, 1, 15, 10, 30, 0)
        expect(described_class.parse_to_date(datetime)).to eq(Date.new(2025, 1, 15))
      end

      it '文字列(YYYY-MM-DD形式)を Date に変換する' do
        expect(described_class.parse_to_date('2025-01-15')).to eq(Date.new(2025, 1, 15))
      end

      it '文字列(YYYY/MM/DD形式)を Date に変換する' do
        expect(described_class.parse_to_date('2025/01/15')).to eq(Date.new(2025, 1, 15))
      end
    end

    context '異常系' do
      it 'nil の場合はデフォルト値(今日の日付)を返す' do
        expect(described_class.parse_to_date(nil)).to eq(Date.current)
      end

      it '空文字の場合はデフォルト値を返す' do
        expect(described_class.parse_to_date('')).to eq(Date.current)
      end

      it '不正な文字列の場合はデフォルト値を返す' do
        expect(described_class.parse_to_date('invalid')).to eq(Date.current)
      end

      it '数値の場合はデフォルト値を返す' do
        expect(described_class.parse_to_date(12345)).to eq(Date.current)
      end

      it 'カスタムデフォルト値を指定できる' do
        custom_default = Date.new(2025, 12, 31)
        expect(described_class.parse_to_date(nil, default: custom_default)).to eq(custom_default)
      end
    end
  end

  describe '.parse_to_beginning_of_day' do
    it 'Date を beginning_of_day に変換する' do
      date = Date.new(2025, 1, 15)
      expected = date.beginning_of_day
      expect(described_class.parse_to_beginning_of_day(date)).to eq(expected)
    end

    it '文字列を beginning_of_day に変換する' do
      expected = Date.new(2025, 1, 15).beginning_of_day
      expect(described_class.parse_to_beginning_of_day('2025-01-15')).to eq(expected)
    end

    it 'Time を beginning_of_day に変換する' do
      time = Time.zone.parse('2025-01-15 15:30:45')
      expected = Date.new(2025, 1, 15).beginning_of_day
      expect(described_class.parse_to_beginning_of_day(time)).to eq(expected)
    end

    it '不正な値の場合はデフォルト値の beginning_of_day を返す' do
      expect(described_class.parse_to_beginning_of_day('invalid')).to eq(Date.current.beginning_of_day)
    end

    it 'カスタムデフォルト値を指定できる' do
      custom_default = Date.new(2025, 12, 31)
      expected = custom_default.beginning_of_day
      expect(described_class.parse_to_beginning_of_day(nil, default: custom_default)).to eq(expected)
    end
  end

  describe '.parse_date_range' do
    it '開始日と終了日から Time の範囲を返す' do
      start_date = '2025-01-01'
      end_date = '2025-01-31'

      expected_start = Date.new(2025, 1, 1).beginning_of_day
      expected_end = Date.new(2025, 1, 31).end_of_day

      result = described_class.parse_date_range(start_date, end_date)

      expect(result.begin).to eq(expected_start)
      expect(result.end).to eq(expected_end)
    end

    it 'Date オブジェクトでも動作する' do
      start_date = Date.new(2025, 1, 1)
      end_date = Date.new(2025, 1, 31)

      expected_start = start_date.beginning_of_day
      expected_end = end_date.end_of_day

      result = described_class.parse_date_range(start_date, end_date)

      expect(result.begin).to eq(expected_start)
      expect(result.end).to eq(expected_end)
    end

    it '不正な値の場合はデフォルト値で範囲を作成する' do
      result = described_class.parse_date_range('invalid', 'invalid')

      expect(result.begin).to eq(Date.current.beginning_of_day)
      expect(result.end).to eq(Date.current.end_of_day)
    end
  end
end
