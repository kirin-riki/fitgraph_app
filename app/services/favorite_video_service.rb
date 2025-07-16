class FavoriteVideoService
  def initialize(user)
    @user = user
  end

  def add_favorite_video(url)
    return { success: false, message: "URLを入力してください" } if url.blank?
    video_id = extract_video_id(url)
    return { success: false, message: "正しいYouTube URLを入力してください" } if video_id.blank?
    return { success: false, message: "お気に入り動画は最大5件までです" } if @user.favorite_videos.count >= 5
    if @user.favorite_videos.find_by(youtube_url: url)
      return { success: false, message: "既に登録されている動画です" }
    end
    video_info = YoutubeApiService.fetch_video_info(video_id)
    if video_info.empty?
      video_info = {
        title: "動画 #{video_id}",
        channel_title: "不明なチャンネル",
        thumbnail_url: "https://img.youtube.com/vi/#{video_id}/default.jpg"
      }
    end
    fav = @user.favorite_videos.build(
      youtube_url: url,
      title: video_info[:title] || "動画 #{video_id}",
      channel_title: video_info[:channel_title] || "不明なチャンネル",
      thumbnail_url: video_info[:thumbnail_url] || "https://img.youtube.com/vi/#{video_id}/default.jpg"
    )
    if fav.save
      { success: true, favorite_video: fav }
    else
      { success: false, message: fav.errors.full_messages.join(", ") }
    end
  rescue => e
    { success: false, message: "エラーが発生しました: #{e.message}" }
  end

  def destroy_favorite_video(user, id)
    fav = user.favorite_videos.find_by(id: id)
    if fav&.destroy
      { success: true }
    else
      { success: false, message: "削除に失敗しました" }
    end
  end

  private

  def extract_video_id(url)
    regex = /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/
    match = url.match(regex)
    match[1] if match
  end
end 