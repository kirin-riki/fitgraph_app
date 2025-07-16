# app/controllers/recommendations_controller.rb
require_relative "../services/youtube_service"

class RecommendedVideosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile_and_condition_key, only: %i[index refresh]

  def index
    service = RecommendedVideoService.new(current_user)
    @condition_key = service.condition_key
    return unless @condition_key

    @videos = RecommendedVideo.where(condition_key: @condition_key)
    @favorite_videos = current_user.favorite_videos.order(created_at: :desc)
    Rails.logger.info "RecommendedVideosController#index: Found #{@videos.count} videos for key: #{@condition_key}"

    if @videos.empty?
      Rails.logger.info "RecommendedVideosController#index: No videos found, fetching from API for key: #{@condition_key}"
      @videos = service.fetch_and_cache_videos
    end
  rescue => e
    handle_error(e, "index")
  end

  def refresh
    service = RecommendedVideoService.new(current_user)
    @condition_key = service.condition_key
    return unless @condition_key

    old_count = service.clear_cache
    Rails.logger.info "RecommendedVideosController#refresh: Deleted #{old_count} old videos for key: #{@condition_key}"

    service.fetch_and_cache_videos
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
      @videos = []
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

  def handle_error(error, action_name)
    Rails.logger.error "RecommendedVideosController##{action_name}: Error: #{error.message}"
    Rails.logger.error "Backtrace: #{error.backtrace.first(5).join("\n")}"
    @videos = []
    flash.now[:danger] = "動画の処理中にエラーが発生しました。"
  end
end
