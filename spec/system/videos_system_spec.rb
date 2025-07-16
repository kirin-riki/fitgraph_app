require 'rails_helper'

RSpec.describe '動画（おすすめ・お気に入り）画面', type: :system do
  let(:user) { User.create!(name: '動画ユーザー', email: 'video_test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:profile) { user.create_profile!(gender: :man, training_intensity: :medium) }

  before do
    driven_by(:rack_test)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password123'
    click_button 'ログイン'
  end

  context 'おすすめ動画' do
    before do
      profile # プロフィールを作成
      5.times do |i|
        RecommendedVideo.create!(
          video_id: "vid#{i}",
          title: "おすすめ動画#{i}",
          thumbnail_url: "https://img.youtube.com/vi/vid#{i}/default.jpg",
          channel_title: "チャンネル#{i}",
          condition_key: profile.condition_key,
          fetched_at: Time.current
        )
      end
      visit recommended_videos_path
    end

    xit 'おすすめ動画が5件表示される' do
      5.times do |i|
        expect(page).to have_content("おすすめ動画#{i}")
        expect(page).to have_content("チャンネル#{i}")
        # iframeやJSでの表示は検証しない
      end
    end

    xit 'サムネイル画像をクリックするとYouTubeページに遷移する（リンクが存在する）' do
      expect(page).to have_selector("a[href*='youtube.com']")
    end
  end

  context 'プロフィール未設定時' do
    xit 'プロフィール設定を促す警告が表示される' do
      visit recommended_videos_path
      expect(page).to have_content('プロフィール設定')
    end
  end

  context '性別・トレーニング強度未設定時' do
    xit '性別またはトレーニング強度未設定の警告が表示される' do
      # profileを作成しない（未設定状態を再現）
      visit recommended_videos_path
      expect(page).to have_content('プロフィール設定')
    end
  end
end
