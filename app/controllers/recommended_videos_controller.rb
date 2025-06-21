# app/controllers/recommendations_controller.rb
require_relative "../services/youtube_service"

class RecommendedVideosController < ApplicationController
  before_action :authenticate_user!

  def index
    begin
      Rails.logger.info "RecommendedVideosController#index: User ID: #{current_user.id}"
      
      unless current_user.profile
        Rails.logger.warn "RecommendedVideosController#index: No profile found for user #{current_user.id}"
        @videos = []
        flash.now[:warning] = "プロフィール設定が必要です。"
        return
      end
      
      Rails.logger.info "RecommendedVideosController#index: Profile found, gender: #{current_user.profile.gender}, training_intensity: #{current_user.profile.training_intensity}"
      
      condition_key = current_user.profile.condition_key
      Rails.logger.info "RecommendedVideosController#index: Condition key: #{condition_key}"
      
      if condition_key.nil?
        Rails.logger.warn "RecommendedVideosController#index: Condition key is nil for user #{current_user.id}"
        @videos = []
        flash.now[:warning] = "プロフィールの性別またはトレーニング強度が設定されていません。"
        return
      end
      
      @videos = RecommendedVideo.where(condition_key: condition_key)
      Rails.logger.info "RecommendedVideosController#index: Found #{@videos.count} videos"
      
      # 動画が存在しない場合、自動でAPIから取得
      if @videos.empty?
        Rails.logger.info "RecommendedVideosController#index: No videos found, fetching from API"
        fetch_and_cache_videos(current_user.profile.gender, current_user.profile.training_intensity)
      end
      
    rescue => e
      Rails.logger.error "RecommendedVideosController#index: Error: #{e.message}"
      Rails.logger.error "RecommendedVideosController#index: Backtrace: #{e.backtrace.first(5).join("\n")}"
      @videos = []
      flash.now[:error] = "動画の取得に失敗しました。"
    end
  end

  def refresh
    Rails.logger.info "RecommendedVideosController#refresh: Starting refresh for user #{current_user.id}"
    
    unless current_user.profile
      Rails.logger.warn "RecommendedVideosController#refresh: No profile found for user #{current_user.id}"
      redirect_to recommended_videos_path, alert: "プロフィール設定が必要です。"
      return
    end

    Rails.logger.info "RecommendedVideosController#refresh: Profile found, gender: #{current_user.profile.gender}, training_intensity: #{current_user.profile.training_intensity}"
    
    condition_key = current_user.profile.condition_key
    Rails.logger.info "RecommendedVideosController#refresh: Condition key: #{condition_key}"

    # 既存のキャッシュを削除
    old_count = RecommendedVideo.where(condition_key: condition_key).count
    Rails.logger.info "RecommendedVideosController#refresh: Deleting #{old_count} old videos for condition_key: #{condition_key}"
    RecommendedVideo.where(condition_key: condition_key).destroy_all

    # 新しい動画を取得
    Rails.logger.info "RecommendedVideosController#refresh: Fetching new videos from YouTube API"
    service = YoutubeService.new
    videos_data = service.fetch_videos(
      gender: current_user.profile.gender,
      intensity: current_user.profile.training_intensity,
      target_count: 5
    )
    
    Rails.logger.info "RecommendedVideosController#refresh: Fetched #{videos_data.size} videos from API"

    # データベースに保存
    saved_count = 0
    videos_data.each do |video_data|
      video_id = video_data.dig("id", "videoId")
      next unless video_id

      Rails.logger.info "RecommendedVideosController#refresh: Saving video #{video_id}"
      
      begin
        RecommendedVideo.create!(
          video_id: video_id,
          title: video_data.dig("snippet", "title"),
          thumbnail_url: video_data.dig("snippet", "thumbnails", "medium", "url"),
          channel_title: video_data.dig("snippet", "channelTitle"),
          view_count: video_data.dig("statistics", "viewCount")&.to_i || 0,
          condition_key: condition_key,
          fetched_at: Time.current
        )
        saved_count += 1
        Rails.logger.info "RecommendedVideosController#refresh: Successfully saved video #{video_id}"
      rescue => e
        Rails.logger.error "RecommendedVideosController#refresh: Failed to save video #{video_id}: #{e.message}"
        # エラーが発生しても処理を続行
        next
      end
    end

    Rails.logger.info "RecommendedVideosController#refresh: Saved #{saved_count} videos out of #{videos_data.size} fetched"
    redirect_to recommended_videos_path, notice: "動画を更新しました（#{saved_count}件保存）"
  end

  private

  def migrate_old_data(gender, intensity)
    # condition_keyがnilの古いデータを削除
    old_videos = current_user.recommended_videos.where(condition_key: nil)
    if old_videos.exists?
      Rails.logger.info "Migrating old data: deleting #{old_videos.count} old videos"
      old_videos.destroy_all
    end
  end

  def fetch_and_cache_videos(gender, intensity)
    target_success_count = 5
    max_api_attempts = 10  # 最大10回のAPIリクエスト
    all_saved_videos = []

    max_api_attempts.times do |api_attempt|
      Rails.logger.info "[Video Save] API試行 #{api_attempt + 1}/#{max_api_attempts}"

      # YouTube APIから動画取得
      items = YoutubeService.new.fetch_videos(
        gender: gender,
        intensity: intensity,
        target_count: 15,  # 10件から15件に変更
        max_results: 40
      )

      Rails.logger.info "[Video Save] APIから取得した動画数: #{items.size}"

      if items.empty?
        Rails.logger.warn "[Video Save] 動画が見つかりませんでした"
        next
      end

      # 取得した動画を保存処理
      items.each_with_index do |item, index|
        Rails.logger.info "[Video Save] 保存処理 #{index + 1}/#{items.size}: #{item.dig('id', 'videoId')}"
        video = create_or_update_video(item, gender, intensity)
        if video
          all_saved_videos << video
          Rails.logger.info "[Video Save] 保存成功: #{video.video_id} (累計: #{all_saved_videos.size})"

          # 目標件数に達したら終了
          if all_saved_videos.size >= target_success_count
            Rails.logger.info "[Video Save] 目標件数達成: #{all_saved_videos.size}件"
            @videos = all_saved_videos.first(target_success_count)
            return
          end
        else
          Rails.logger.error "[Video Save] 保存失敗: #{item.dig('id', 'videoId')}"
        end
      end

      Rails.logger.info "[Video Save] この試行での保存件数: #{all_saved_videos.size}"
    end

    # 最大試行回数に達した場合
    Rails.logger.info "[Video Save] 最大試行回数に達しました。最終保存件数: #{all_saved_videos.size}"
    @videos = all_saved_videos.first(target_success_count)

    if all_saved_videos.empty?
      flash.now[:warning] = "条件に合う動画が見つかりませんでした。"
    elsif all_saved_videos.size < target_success_count
      flash.now[:warning] = "一部の動画のみ取得できました。（#{all_saved_videos.size}件）"
    end
  end

  def create_or_update_video(item, gender, intensity)
    vid  = item["id"]["videoId"]
    snip = item["snippet"]
    condition_key = "#{gender}_#{intensity}"

    rec = current_user.recommended_videos
                      .find_or_initialize_by(
                        video_id: vid,
                        condition_key: condition_key
                      )

    rec.title         = snip["title"]
    rec.thumbnail_url = snip["thumbnails"]["medium"]["url"]
    rec.channel_title = snip["channelTitle"]
    rec.view_count    = snip.dig("statistics", "viewCount")&.to_i || 0
    rec.fetched_at    = Time.current

    if rec.save
      rec
    else
      Rails.logger.error "Failed to save video: #{rec.errors.full_messages} (condition_key: #{condition_key})"
      nil
    end
  rescue => e
    Rails.logger.error "Error processing video item: #{e.message} (condition_key: #{condition_key})"
    nil
  end
end
