FactoryBot.define do
  factory :favorite_video do
    association :user
    youtube_url { "https://youtube.com/watch?v=#{SecureRandom.hex(4)}" }
    title { "テスト動画" }
    thumbnail_url { "https://img.youtube.com/vi/#{SecureRandom.hex(4)}/default.jpg" }
    channel_title { "テストチャンネル" }
  end
end 