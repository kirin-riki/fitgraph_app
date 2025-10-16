require 'rails_helper'

RSpec.describe BodyRecordFinder do
  let(:user) { create(:user) }
  let(:finder) { described_class.new(user) }

  describe '#find_for_calendar' do
    let(:selected_date) { Date.new(2025, 1, 15) } # 2025年1月15日(水)

    context 'レコードが存在する場合' do
      let!(:record1) { create(:body_record, user: user, recorded_at: Date.new(2025, 1, 1).beginning_of_day, weight: 70.0) }
      let!(:record2) { create(:body_record, user: user, recorded_at: Date.new(2025, 1, 15).beginning_of_day, weight: 71.0) }
      let!(:record3) { create(:body_record, user: user, recorded_at: Date.new(2025, 1, 31).beginning_of_day, weight: 72.0) }
      # 範囲外のレコード(2月2日以降)
      let!(:record_outside) { create(:body_record, user: user, recorded_at: Date.new(2025, 2, 5).beginning_of_day, weight: 73.0) }

      it 'カレンダー範囲内のレコードを返す' do
        result = finder.find_for_calendar(selected_date)

        expect(result[:body_records]).to include(record1, record2, record3)
        expect(result[:body_records]).not_to include(record_outside)
      end

      it 'レコードが存在する日付のリストを返す' do
        result = finder.find_for_calendar(selected_date)

        expect(result[:days_with_records]).to contain_exactly(
          Date.new(2025, 1, 1),
          Date.new(2025, 1, 15),
          Date.new(2025, 1, 31)
        )
      end

      it 'カレンダーの日付範囲を返す' do
        result = finder.find_for_calendar(selected_date)

        # 2025年1月のカレンダー範囲
        # beginning_of_month.beginning_of_week(:sunday) = 2024/12/29(日)
        # end_of_month.end_of_week(:sunday) = 2025/2/1(土)
        expect(result[:date_range].first).to eq(Date.new(2024, 12, 29))
        expect(result[:date_range].last).to eq(Date.new(2025, 2, 1))
      end
    end

    context 'レコードが存在しない場合' do
      it '空の配列を返す' do
        result = finder.find_for_calendar(selected_date)

        expect(result[:body_records]).to be_empty
        expect(result[:days_with_records]).to be_empty
      end

      it 'カレンダーの日付範囲は返す' do
        result = finder.find_for_calendar(selected_date)

        expect(result[:date_range]).not_to be_nil
        expect(result[:date_range].first).to eq(Date.new(2024, 12, 29))
        expect(result[:date_range].last).to eq(Date.new(2025, 2, 1))
      end
    end

    context '文字列の日付を渡した場合' do
      it '正しくパースしてレコードを取得する' do
        create(:body_record, user: user, recorded_at: Date.new(2025, 1, 15).beginning_of_day)

        result = finder.find_for_calendar('2025-01-15')

        expect(result[:body_records].count).to eq(1)
      end
    end

    context '他のユーザーのレコードが存在する場合' do
      let(:other_user) { create(:user) }
      let!(:other_record) { create(:body_record, user: other_user, recorded_at: Date.new(2025, 1, 15).beginning_of_day) }

      it '他のユーザーのレコードは含まれない' do
        result = finder.find_for_calendar(selected_date)

        expect(result[:body_records]).not_to include(other_record)
      end
    end
  end

  describe '#find_or_build_for_date' do
    let(:target_date) { Date.new(2025, 1, 15) }

    context 'レコードが存在する場合' do
      let!(:existing_record) { create(:body_record, user: user, recorded_at: target_date.beginning_of_day, weight: 70.0) }

      it '既存のレコードを返す' do
        result = finder.find_or_build_for_date(target_date)

        expect(result).to eq(existing_record)
        expect(result.persisted?).to be true
      end
    end

    context 'レコードが存在しない場合' do
      it '新規レコードを構築して返す(未保存)' do
        result = finder.find_or_build_for_date(target_date)

        expect(result).to be_a(BodyRecord)
        expect(result.persisted?).to be false
        expect(result.user).to eq(user)
        expect(result.recorded_at.to_date).to eq(target_date)
      end
    end

    context '文字列の日付を渡した場合' do
      it '正しくパースして検索する' do
        create(:body_record, user: user, recorded_at: target_date.beginning_of_day)

        result = finder.find_or_build_for_date('2025-01-15')

        expect(result.persisted?).to be true
        expect(result.recorded_at.to_date).to eq(target_date)
      end
    end
  end

  describe '#find_or_initialize_for_date' do
    let(:target_date) { Date.new(2025, 1, 15) }

    context 'レコードが存在する場合' do
      let!(:existing_record) { create(:body_record, user: user, recorded_at: target_date.beginning_of_day, weight: 70.0) }

      it '既存のレコードを返す' do
        result = finder.find_or_initialize_for_date(target_date)

        expect(result).to eq(existing_record)
        expect(result.persisted?).to be true
      end
    end

    context 'レコードが存在しない場合' do
      it '新規レコードを初期化して返す(未保存)' do
        result = finder.find_or_initialize_for_date(target_date)

        expect(result).to be_a(BodyRecord)
        expect(result.persisted?).to be false
        expect(result.user).to eq(user)
        expect(result.recorded_at).to eq(target_date.beginning_of_day)
      end
    end

    context '文字列の日付を渡した場合' do
      it '正しくパースして初期化する' do
        result = finder.find_or_initialize_for_date('2025-01-15')

        expect(result.persisted?).to be false
        expect(result.recorded_at).to eq(target_date.beginning_of_day)
      end
    end

    context '不正な日付文字列を渡した場合' do
      it 'デフォルト値(今日)で初期化する' do
        result = finder.find_or_initialize_for_date('invalid')

        expect(result.persisted?).to be false
        expect(result.recorded_at).to eq(Date.current.beginning_of_day)
      end
    end
  end
end
