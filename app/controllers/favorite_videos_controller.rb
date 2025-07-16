class FavoriteVideosController < ApplicationController
  before_action :authenticate_user!

  require "net/http"
  require "json"

  def create
    url = params[:youtube_url]
    result = FavoriteVideoService.new(current_user).add_favorite_video(url)
    if result[:success]
      fav = result[:favorite_video]
      respond_to do |format|
        format.json {
          render json: {
            success: true,
            message: "お気に入り動画を追加しました",
            favorite_video: {
              id: fav.id,
              title: fav.title,
              channel_title: fav.channel_title,
              youtube_url: fav.youtube_url,
              thumbnail_url: fav.thumbnail_url
            }
          }
        }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), success: "お気に入り動画を追加しました" }
      end
    else
      respond_to do |format|
        format.json {
          render json: {
            success: false,
            message: result[:message]
          }, status: :unprocessable_entity
        }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: result[:message] }
      end
    end
  end

  def destroy
    result = FavoriteVideoService.new(current_user).destroy_favorite_video(current_user, params[:id])
    if result[:success]
      respond_to do |format|
        format.json { render json: { success: true, message: "お気に入り動画を削除しました" } }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), success: "お気に入り動画を削除しました" }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, message: result[:message] }, status: :unprocessable_entity }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: result[:message] }
      end
    end
  end

  private
end
