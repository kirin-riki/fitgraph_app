require 'rails_helper'

RSpec.describe BodyRecord, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end

  describe 'バリデーション' do
    context 'weight' do
      it '0以上300以下の数値であること' do
        should validate_numericality_of(:weight)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(300)
      end

      it 'nil の場合は valid' do
        record = build(:body_record, weight: nil)
        expect(record).to be_valid
      end

      it '0 の場合は valid' do
        record = build(:body_record, weight: 0)
        expect(record).to be_valid
      end

      it '300 の場合は valid' do
        record = build(:body_record, weight: 300)
        expect(record).to be_valid
      end

      it '-1 の場合は invalid' do
        record = build(:body_record, weight: -1)
        expect(record).not_to be_valid
        expect(record.errors[:weight]).to be_present
      end

      it '301 の場合は invalid' do
        record = build(:body_record, weight: 301)
        expect(record).not_to be_valid
        expect(record.errors[:weight]).to be_present
      end
    end

    context 'body_fat' do
      it '0以上100以下の数値であること' do
        should validate_numericality_of(:body_fat)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(100)
      end

      it 'nil の場合は valid' do
        record = build(:body_record, body_fat: nil)
        expect(record).to be_valid
      end

      it '0 の場合は valid' do
        record = build(:body_record, body_fat: 0)
        expect(record).to be_valid
      end

      it '100 の場合は valid' do
        record = build(:body_record, body_fat: 100)
        expect(record).to be_valid
      end

      it '-1 の場合は invalid' do
        record = build(:body_record, body_fat: -1)
        expect(record).not_to be_valid
        expect(record.errors[:body_fat]).to be_present
      end

      it '101 の場合は invalid' do
        record = build(:body_record, body_fat: 101)
        expect(record).not_to be_valid
        expect(record.errors[:body_fat]).to be_present
      end
    end
  end

  describe 'ActiveStorage' do
    it 'photo が添付できること' do
      record = create(:body_record)
      expect(record.photo).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe 'データ作成' do
    it 'Factory Bot で正常に作成できること' do
      record = build(:body_record)
      expect(record).to be_valid
    end

    it '保存すると created_at と updated_at が設定されること' do
      record = create(:body_record)
      expect(record.created_at).to be_present
      expect(record.updated_at).to be_present
    end
  end
end
