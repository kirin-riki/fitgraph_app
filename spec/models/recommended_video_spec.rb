require 'rails_helper'

RSpec.describe RecommendedVideo, type: :model do
  describe 'バリデーション' do
    let(:valid_attrs) do
      {
        title: 'タイトル',
        fetched_at: Time.current,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    it 'video_idが必須であること' do
      video = RecommendedVideo.new(valid_attrs.merge(video_id: nil, condition_key: 'key'))
      video.valid?
      expect(video.errors[:video_id]).to be_present
    end

    it 'condition_keyが必須であること' do
      video = RecommendedVideo.new(valid_attrs.merge(video_id: 'vid', condition_key: nil))
      video.valid?
      expect(video.errors[:condition_key]).to be_present
    end

    it 'video_idがcondition_keyスコープで一意であること' do
      RecommendedVideo.create!(valid_attrs.merge(video_id: 'vid', condition_key: 'key'))
      video = RecommendedVideo.new(valid_attrs.merge(video_id: 'vid', condition_key: 'key'))
      video.valid?
      expect(video.errors[:video_id]).to be_present
    end
  end

  describe '独自メソッド' do
    describe '.condition_key' do
      it 'genderとintensityからkeyを返す' do
        expect(RecommendedVideo.condition_key('man', 'low')).to eq('man_low')
      end
    end
  end

  describe 'スコープ' do
    let!(:video1) { RecommendedVideo.create!(video_id: 'v1', title: 't', fetched_at: 6.months.ago, created_at: Time.current, updated_at: Time.current, condition_key: 'man_low') }
    let!(:video2) { RecommendedVideo.create!(video_id: 'v2', title: 't', fetched_at: 1.month.ago, created_at: Time.current, updated_at: Time.current, condition_key: 'man_low') }
    let!(:video3) { RecommendedVideo.create!(video_id: 'v3', title: 't', fetched_at: 1.month.ago, created_at: Time.current, updated_at: Time.current, condition_key: 'woman_high') }

    describe '.recent' do
      it '指定月数以内の動画のみ返す' do
        expect(RecommendedVideo.recent(3)).to include(video2, video3)
        expect(RecommendedVideo.recent(3)).not_to include(video1)
      end
    end

    describe '.for_conditions' do
      it 'genderとintensityに合致する動画のみ返す' do
        expect(RecommendedVideo.for_conditions('man', 'low')).to include(video1, video2)
        expect(RecommendedVideo.for_conditions('man', 'low')).not_to include(video3)
      end
    end
  end

  # RecommendedVideoモデルは他モデルとのアソシエーションがありません
end
