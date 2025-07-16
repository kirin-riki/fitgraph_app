require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe User, type: :model do
  describe 'バリデーション' do
    it '名前が必須であること', skip: '一時的にskip' do
      user = User.new(name: nil)
      user.valid?
      expect(user.errors[:name]).to be_present
    end

    it '名前が255文字以内であること', skip: '一時的にskip' do
      user = User.new(name: 'a' * 256)
      user.valid?
      expect(user.errors[:name]).to be_present
    end

    it 'パスワードが6文字以上であること', skip: '一時的にskip' do
      user = User.new(password: '12345', password_confirmation: '12345', name: 'test', email: 'test@example.com', uid: 'uid', provider: 'provider')
      user.valid?
      expect(user.errors[:password]).to be_present
    end

    it 'パスワード確認が必須であること', skip: '一時的にskip' do
      user = User.new(password: '123456', password_confirmation: nil, name: 'test', email: 'test@example.com', uid: 'uid', provider: 'provider')
      user.valid?
      expect(user.errors[:password_confirmation]).to be_present
    end

    it 'uidがproviderスコープで一意であること', skip: '一時的にskip' do
      User.create!(name: 'test', email: 'test1@example.com', password: '123456', password_confirmation: '123456', uid: 'uid1', provider: 'google')
      user = User.new(name: 'test2', email: 'test2@example.com', password: '123456', password_confirmation: '123456', uid: 'uid1', provider: 'google')
      user.valid?
      expect(user.errors[:uid]).to be_present
    end
  end

  describe 'アソシエーション' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_many(:body_records) }
    it { should have_many(:favorite_videos).dependent(:destroy) }
  end

  describe '独自メソッド' do
    describe '.create_unique_string' do
      it 'ユニークな文字列(UUID)を返す' do
        str1 = User.create_unique_string
        str2 = User.create_unique_string
        expect(str1).to be_a(String)
        expect(str1).not_to eq(str2)
      end
    end

    describe '#provisioning_uri' do
      it 'OTP用のURIを返す' do
        user = User.new(email: 'test@example.com')
        allow(user).to receive(:otp_provisioning_uri).and_return('otpauth://example')
        expect(user.provisioning_uri).to eq('otpauth://example')
      end
    end
  end
end
