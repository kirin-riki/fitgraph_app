require 'rails_helper'

RSpec.describe BodyRecordForm do
  describe 'バリデーション' do
    context '正常系' do
      it '有効な値の場合は valid' do
        form = described_class.new(
          recorded_at: '2025-01-15',
          weight: 70.5,
          body_fat: 18.3,
          fat_mass: 12.9
        )

        expect(form).to be_valid
      end

      it 'weight が nil でも valid' do
        form = described_class.new(
          recorded_at: '2025-01-15',
          weight: nil,
          body_fat: 18.3
        )

        expect(form).to be_valid
      end

      it 'body_fat が nil でも valid' do
        form = described_class.new(
          recorded_at: '2025-01-15',
          weight: 70.5,
          body_fat: nil
        )

        expect(form).to be_valid
      end
    end

    context 'weight のバリデーション' do
      it 'weight が 0 未満の場合は invalid' do
        form = described_class.new(weight: -1)
        expect(form).not_to be_valid
        expect(form.errors[:weight]).to be_present
      end

      it 'weight が 300 を超える場合は invalid' do
        form = described_class.new(weight: 301)
        expect(form).not_to be_valid
        expect(form.errors[:weight]).to be_present
      end

      it 'weight が 0 の場合は valid' do
        form = described_class.new(weight: 0)
        expect(form).to be_valid
      end

      it 'weight が 300 の場合は valid' do
        form = described_class.new(weight: 300)
        expect(form).to be_valid
      end
    end

    context 'body_fat のバリデーション' do
      it 'body_fat が 0 未満の場合は invalid' do
        form = described_class.new(body_fat: -1)
        expect(form).not_to be_valid
        expect(form.errors[:body_fat]).to be_present
      end

      it 'body_fat が 100 を超える場合は invalid' do
        form = described_class.new(body_fat: 101)
        expect(form).not_to be_valid
        expect(form.errors[:body_fat]).to be_present
      end

      it 'body_fat が 0 の場合は valid' do
        form = described_class.new(body_fat: 0)
        expect(form).to be_valid
      end

      it 'body_fat が 100 の場合は valid' do
        form = described_class.new(body_fat: 100)
        expect(form).to be_valid
      end
    end

    context 'fat_mass のバリデーション' do
      it 'fat_mass が 0 未満の場合は invalid' do
        form = described_class.new(fat_mass: -1)
        expect(form).not_to be_valid
        expect(form.errors[:fat_mass]).to be_present
      end

      it 'fat_mass が 0 の場合は valid' do
        form = described_class.new(fat_mass: 0)
        expect(form).to be_valid
      end

      it 'fat_mass が nil の場合は valid' do
        form = described_class.new(fat_mass: nil)
        expect(form).to be_valid
      end
    end
  end

  describe '#initialize' do
    it '文字列の日付を recorded_at に指定すると beginning_of_day に変換される' do
      form = described_class.new(recorded_at: '2025-01-15')

      expect(form.recorded_at).to eq(Date.new(2025, 1, 15).beginning_of_day)
    end

    it 'Date オブジェクトを recorded_at に指定すると beginning_of_day に変換される' do
      form = described_class.new(recorded_at: Date.new(2025, 1, 15))

      expect(form.recorded_at).to eq(Date.new(2025, 1, 15).beginning_of_day)
    end

    it 'recorded_at が nil の場合は nil のまま' do
      form = described_class.new(recorded_at: nil)

      expect(form.recorded_at).to be_nil
    end

    it '不正な日付文字列の場合はデフォルト値の beginning_of_day' do
      form = described_class.new(recorded_at: 'invalid')

      expect(form.recorded_at).to eq(Date.current.beginning_of_day)
    end
  end

  describe '#body_record_attributes' do
    it 'BodyRecord に保存する属性を返す(photo 以外)' do
      recorded_at = Date.new(2025, 1, 15).beginning_of_day
      form = described_class.new(
        recorded_at: recorded_at,
        weight: 70.5,
        body_fat: 18.3,
        fat_mass: 12.9,
        photo: 'dummy_photo'
      )

      attributes = form.body_record_attributes

      expect(attributes).to eq({
        recorded_at: recorded_at,
        weight: 70.5,
        body_fat: 18.3,
        fat_mass: 12.9
      })
      expect(attributes).not_to have_key(:photo)
    end
  end

  describe '#photo_attached?' do
    it 'photo が存在する場合は true' do
      form = described_class.new(photo: 'dummy_photo')
      expect(form.photo_attached?).to be true
    end

    it 'photo が nil の場合は false' do
      form = described_class.new(photo: nil)
      expect(form.photo_attached?).to be false
    end

    it 'photo が空文字の場合は false' do
      form = described_class.new(photo: '')
      expect(form.photo_attached?).to be false
    end
  end
end
