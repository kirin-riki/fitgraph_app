# app/controllers/recommendations_controller.rb
require_relative '../services/youtube_service'

class RecommendedVideosController < ApplicationController
  before_action :authenticate_user!

  def index
    begin
      # Profileが存在しない場合のフォールバック
      profile = current_user.profile
      unless profile
        @videos = []
        flash.now[:warning] = "プロフィール設定が必要です。"
        return
      end

      # 既存データの移行処理（condition_keyがnilのデータを削除）
      migrate_old_data(profile.gender, profile.training_intensity)

      # 条件別キャッシュ確認（3ヶ月以内）
      cache = current_user.recommended_videos
                          .for_conditions(profile.gender, profile.training_intensity)
                          .recent(3)
                          .order(fetched_at: :desc)
                          .limit(5)

      Rails.logger.info "キャッシュ件数: #{cache.size} (条件: #{profile.gender}_#{profile.training_intensity})"
      cache.each_with_index { |v, i| Rails.logger.info "キャッシュ#{i+1}: #{v.video_id}, #{v.fetched_at}" }

      if cache.size >= 5
        Rails.logger.info "Using cached videos for user #{current_user.id} with conditions: #{profile.gender}_#{profile.training_intensity}"
        @videos = cache
      else
        Rails.logger.info "Fetching new videos for user #{current_user.id} with conditions: #{profile.gender}_#{profile.training_intensity}"
        fetch_and_cache_videos(profile.gender, profile.training_intensity)
      end
    rescue => e
      Rails.logger.error "Error in RecommendedVideosController#index: #{e.message}"
      @videos = []
      flash.now[:error] = "動画の取得に失敗しました。しばらく時間をおいて再度お試しください。"
    end
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
    condition_key = RecommendedVideo.condition_key(gender, intensity)

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
