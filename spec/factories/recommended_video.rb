FactoryBot.define do
  factory :recommended_video do
    video_id { SecureRandom.hex(4) }
    title { "おすすめ動画" }
    thumbnail_url { "https://img.youtube.com/vi/#{SecureRandom.hex(4)}/default.jpg" }
    channel_title { "おすすめチャンネル" }
    view_count { 100 }
    fetched_at { Time.current }
    condition_key { "man_low" }
    created_at { Time.current }
    updated_at { Time.current }
  end
end 