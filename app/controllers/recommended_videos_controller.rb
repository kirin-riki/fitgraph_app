# app/controllers/recommendations_controller.rb
require_relative "../services/youtube_service"

class RecommendedVideosController < ApplicationController
  before_action :authenticate_user!

  def index
    @videos = RecommendedVideo.where(condition_key: current_user.profile.condition_key)
  end

  def refresh
    # 既存のキャッシュを削除
    RecommendedVideo.where(condition_key: current_user.profile.condition_key).destroy_all

    # 新しい動画を取得
    service = YoutubeService.new
    videos_data = service.fetch_videos(
      gender: current_user.profile.gender,
      intensity: current_user.profile.intensity,
      target_count: 15
    )

    # データベースに保存
    videos_data.each do |video_data|
      video_id = video_data.dig("id", "videoId")
      next unless video_id

      RecommendedVideo.create!(
        video_id: video_id,
        title: video_data.dig("snippet", "title"),
        thumbnail_url: video_data.dig("snippet", "thumbnails", "medium", "url"),
        channel_title: video_data.dig("snippet", "channelTitle"),
        view_count: video_data.dig("statistics", "viewCount")&.to_i || 0,
        condition_key: current_user.profile.condition_key,
        fetched_at: Time.current
      )
    rescue => e
      # エラーが発生しても処理を続行
      next
    end

    redirect_to recommended_videos_path, notice: "動画を更新しました"
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
