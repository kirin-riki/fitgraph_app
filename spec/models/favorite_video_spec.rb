require 'rails_helper'

# 全テスト一時停止中（必要なものだけ有効化してください）
RSpec.describe FavoriteVideo, type: :model do
  describe 'バリデーション' do
    let(:user) { User.create!(name: 'test', email: 'test@example.com', password: '123456', password_confirmation: '123456', uid: 'uid', provider: 'google') }

    it 'youtube_urlが必須であること' do
      video = FavoriteVideo.new(youtube_url: nil, user: user)
      video.valid?
      expect(video.errors[:youtube_url]).to be_present
    end

    it 'youtube_urlがuser_idスコープで一意であること' do
      FavoriteVideo.create!(youtube_url: 'url1', user: user, title: 'title', thumbnail_url: 'thumb', channel_title: 'channel')
      video = FavoriteVideo.new(youtube_url: 'url1', user: user, title: 'title', thumbnail_url: 'thumb', channel_title: 'channel')
      video.valid?
      expect(video.errors[:youtube_url]).to be_present
    end

    it 'お気に入り動画が5件を超えると無効であること' do
      5.times do |i|
        FavoriteVideo.create!(youtube_url: "url#{i}", user: user, title: 'title', thumbnail_url: 'thumb', channel_title: 'channel')
      end
      video = FavoriteVideo.new(youtube_url: 'url6', user: user, title: 'title', thumbnail_url: 'thumb', channel_title: 'channel')
      video.valid?
      expect(video.errors[:base]).to be_present
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end
end
