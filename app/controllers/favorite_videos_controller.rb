class FavoriteVideosController < ApplicationController
  before_action :authenticate_user!

  require "net/http"
  require "json"

  def create
    begin
      url = params[:youtube_url]

      if url.blank?
        respond_to do |format|
          format.json { render json: { success: false, message: "URLを入力してください" }, status: :bad_request }
          format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "URLを入力してください" }
        end
        return
      end

      video_id = extract_video_id(url)

      if video_id.blank?
        respond_to do |format|
          format.json { render json: { success: false, message: "正しいYouTube URLを入力してください" }, status: :bad_request }
          format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "正しいYouTube URLを入力してください" }
        end
        return
      end

      # 既に5件登録済みならエラー
      if current_user.favorite_videos.count >= 5
        respond_to do |format|
          format.json { render json: { success: false, message: "お気に入り動画は最大5件までです" }, status: :unprocessable_entity }
          format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "お気に入り動画は最大5件までです" }
        end
        return
      end

      # 既に同じ動画が登録されているかチェック
      existing_video = current_user.favorite_videos.find_by(youtube_url: url)
      if existing_video
        respond_to do |format|
          format.json { render json: { success: false, message: "既に登録されている動画です" }, status: :unprocessable_entity }
          format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "既に登録されている動画です" }
        end
        return
      end

      # YouTube APIから動画情報を取得
      video_info = YoutubeApiService.fetch_video_info(video_id)

      # APIキーが設定されていない場合やAPI呼び出しが失敗した場合のフォールバック
      if video_info.empty?
        video_info = {
          title: "動画 #{video_id}",
          channel_title: "不明なチャンネル",
          thumbnail_url: "https://img.youtube.com/vi/#{video_id}/default.jpg"
        }
      end

      fav = current_user.favorite_videos.build(
        youtube_url: url,
        title: video_info[:title] || "動画 #{video_id}",
        channel_title: video_info[:channel_title] || "不明なチャンネル",
        thumbnail_url: video_info[:thumbnail_url] || "https://img.youtube.com/vi/#{video_id}/default.jpg"
      )

      if fav.save
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
              message: fav.errors.full_messages.join(", ")
            }, status: :unprocessable_entity
          }
          format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: fav.errors.full_messages.join(", ") }
        end
      end
    rescue => e
      respond_to do |format|
        format.json {
          render json: {
            success: false,
            message: "エラーが発生しました: #{e.message}"
          }, status: :internal_server_error
        }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "エラーが発生しました: #{e.message}" }
      end
    end
  end

  def destroy
    fav = current_user.favorite_videos.find_by(id: params[:id])

    if fav&.destroy
      respond_to do |format|
        format.json { render json: { success: true, message: "お気に入り動画を削除しました" } }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), success: "お気に入り動画を削除しました" }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, message: "削除に失敗しました" }, status: :unprocessable_entity }
        format.html { redirect_to recommended_videos_path(tab: "favorite"), danger: "削除に失敗しました" }
      end
    end
  end

  private

  # YouTube URLからvideo_idを抽出
  def extract_video_id(url)
    # より包括的な正規表現でYouTube URLに対応
    # 対応形式:
    # - https://www.youtube.com/watch?v=VIDEO_ID
    # - https://youtu.be/VIDEO_ID
    # - https://www.youtube.com/embed/VIDEO_ID
    # - https://youtu.be/VIDEO_ID?si=...
    regex = /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/
    match = url.match(regex)
    match[1] if match
  end

  # YouTube APIから動画情報を取得
  def fetch_youtube_video_info(video_id)
    # このメソッドは実装が必要です。
    # 実装方法はYouTube APIを使用して動画情報を取得する方法を検討する必要があります。
    # ここでは仮実装として空のハッシュを返します。
    {}
  end
end
