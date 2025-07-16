require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'バリデーション' do
    it 'heightが0より大きい整数であること' do
      profile = Profile.new(height: 0)
      profile.valid?
      expect(profile.errors[:height]).to be_present
      profile = Profile.new(height: -1)
      profile.valid?
      expect(profile.errors[:height]).to be_present
      profile = Profile.new(height: 170)
      profile.valid?
      expect(profile.errors[:height]).to be_blank
    end

    it 'target_weightが0より大きい整数であること' do
      profile = Profile.new(target_weight: 0)
      profile.valid?
      expect(profile.errors[:target_weight]).to be_present
      profile = Profile.new(target_weight: -1)
      profile.valid?
      expect(profile.errors[:target_weight]).to be_present
      profile = Profile.new(target_weight: 60)
      profile.valid?
      expect(profile.errors[:target_weight]).to be_blank
    end
  end

  describe 'enum/デフォルト値' do
    it 'genderの初期値はmanであること' do
      profile = Profile.new
      expect(profile.gender).to eq('man')
    end
    it 'training_intensityの初期値はlowであること' do
      profile = Profile.new
      expect(profile.training_intensity).to eq('low')
    end
    it 'genderの値が正しいこと' do
      expect(Profile.genders.keys).to contain_exactly('man', 'woman', 'other')
    end
    it 'training_intensityの値が正しいこと' do
      expect(Profile.training_intensities.keys).to contain_exactly('low', 'medium', 'high')
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end

  describe '独自メソッド' do
    describe '#condition_key' do
      it 'genderとtraining_intensityが両方nilならnilを返す' do
        profile = Profile.new(gender: nil, training_intensity: nil)
        expect(profile.condition_key).to be_nil
      end
      it 'genderとtraining_intensityが両方存在すればkeyを返す' do
        profile = Profile.new(gender: 'man', training_intensity: 'low')
        expect(profile.condition_key).to eq('man_low')
      end
    end
  end
end
