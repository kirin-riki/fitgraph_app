# app/controllers/recommendations_controller.rb
require_relative "../services/youtube_service"

class RecommendedVideosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile_and_condition_key, only: %i[index refresh]

  def index
    return unless @condition_key

    @videos = RecommendedVideo.where(condition_key: @condition_key)
    Rails.logger.info "RecommendedVideosController#index: Found #{@videos.count} videos for key: #{@condition_key}"

    # 動画が存在しない場合、自動でAPIから取得
    if @videos.empty?
      Rails.logger.info "RecommendedVideosController#index: No videos found, fetching from API for key: #{@condition_key}"
      fetch_and_cache_videos
    end
  rescue => e
    handle_error(e, "index")
  end

  def refresh
    return unless @condition_key

    # 既存のキャッシュを削除
    old_count = RecommendedVideo.where(condition_key: @condition_key).destroy_all.size
    Rails.logger.info "RecommendedVideosController#refresh: Deleted #{old_count} old videos for key: #{@condition_key}"

    # 新しい動画を取得してリダイレクト
    fetch_and_cache_videos
    redirect_to recommended_videos_path, notice: "動画を更新しました。"
  rescue => e
    handle_error(e, "refresh")
    redirect_to recommended_videos_path, alert: "動画の更新に失敗しました。"
  end

  private

  def set_profile_and_condition_key
    @profile = current_user.profile
    unless @profile
      Rails.logger.warn "User #{current_user.id} has no profile."
      flash.now[:warning] = "おすすめ動画を表示するには、まずプロフィール設定が必要です。"
      # indexアクションの場合はレンダリングを許可し、refreshの場合はリダイレクトするなどの処理をここに書くこともできる
      # 今回はシンプルにするため、flashで通知するのみ
      @videos = [] # indexビューがエラーにならないように空配列をセット
      return
    end

    @condition_key = @profile.condition_key
    unless @condition_key
      Rails.logger.warn "User #{current_user.id} profile has no condition key."
      flash.now[:warning] = "プロフィールの性別またはトレーニング強度が設定されていません。"
      @videos = []
      nil
    end
  end

  def fetch_and_cache_videos
    service = YoutubeService.new
    videos_data = service.fetch_videos(
      gender: @profile.gender,
      intensity: @profile.training_intensity,
      target_count: 5,
      max_results: 50 # 多めに取得してフィルタリング
    )

    saved_videos = []
    videos_data.each do |video_data|
      break if saved_videos.size >= 5
      video = create_video_from_data(video_data)
      saved_videos << video if video
    end

    Rails.logger.info "Saved #{saved_videos.size} new videos for key: #{@condition_key}"
    @videos = RecommendedVideo.where(condition_key: @condition_key).limit(5)

    if @videos.empty?
      flash.now[:warning] = "条件に合う動画が見つかりませんでした。"
    end
  end

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
    # 既に同じvideo_idとcondition_keyの組み合わせが存在する場合は何もしない
    Rails.logger.warn "Video #{video_id} for key #{@condition_key} already exists. Skipping."
    nil
  rescue => e
    Rails.logger.error "Failed to save video #{video_id} for key #{@condition_key}: #{e.message}"
    nil
  end

  def handle_error(error, action_name)
    Rails.logger.error "RecommendedVideosController##{action_name}: Error: #{error.message}"
    Rails.logger.error "Backtrace: #{error.backtrace.first(5).join("\n")}"
    @videos = []
    flash.now[:error] = "動画の処理中にエラーが発生しました。"
  end
end
