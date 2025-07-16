class RecommendedVideoService
  def initialize(user)
    @user = user
    @profile = user.profile
    @condition_key = @profile&.condition_key
  end

  attr_reader :condition_key

  def fetch_and_cache_videos
    return [] unless @profile && @condition_key
    service = YoutubeService.new
    videos_data = service.fetch_videos(
      gender: @profile.gender,
      intensity: @profile.training_intensity,
      target_count: 5,
      max_results: 50
    )
    saved_videos = []
    videos_data.each do |video_data|
      break if saved_videos.size >= 5
      video = create_video_from_data(video_data)
      saved_videos << video if video
    end
    RecommendedVideo.where(condition_key: @condition_key).limit(5)
  end

  def clear_cache
    RecommendedVideo.where(condition_key: @condition_key).destroy_all.size
  end

  private

  def create_video_from_data(video_data)
    video_id = video_data.dig("id", "videoId")
    return nil unless video_id
    RecommendedVideo.create(
      video_id: video_id,
      title: video_data.dig("snippet", "title"),
      thumbnail_url: video_data.dig("snippet", "thumbnails", "medium", "url"),
      channel_title: video_data.dig("snippet", "channelTitle"),
      view_count: video_data.dig("statistics", "viewCount")&.to_i || 0,
      condition_key: @condition_key,
      fetched_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn "Video \\#{video_id} for key \\#{@condition_key} already exists. Skipping."
    nil
  rescue => e
    Rails.logger.error "Failed to save video \\#{video_id} for key \\#{@condition_key}: \\#{e.message}"
    nil
  end
end
