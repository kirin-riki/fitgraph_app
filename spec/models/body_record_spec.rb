require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe BodyRecord, type: :model do
  describe 'バリデーション' do
    it 'weightが0以上300以下の数値であること' do
      record = BodyRecord.new(weight: -1)
      record.valid?
      expect(record.errors[:weight]).to be_present
      record = BodyRecord.new(weight: 301)
      record.valid?
      expect(record.errors[:weight]).to be_present
      record = BodyRecord.new(weight: 150)
      record.valid?
      expect(record.errors[:weight]).to be_blank
    end

    it 'body_fatが0以上100以下の数値であること' do
      record = BodyRecord.new(body_fat: -1)
      record.valid?
      expect(record.errors[:body_fat]).to be_present
      record = BodyRecord.new(body_fat: 101)
      record.valid?
      expect(record.errors[:body_fat]).to be_present
      record = BodyRecord.new(body_fat: 50)
      record.valid?
      expect(record.errors[:body_fat]).to be_blank
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should have_one_attached(:photo) }
  end
end
