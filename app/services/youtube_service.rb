require 'net/http'
require 'uri'
require 'json'

class YoutubeService
  BASE_URL = "https://www.googleapis.com/youtube/v3/search".freeze

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
  end

  def fetch_videos(gender:, intensity:, target_count: 5, max_results: 40)
    all_items = []
    page_token = nil
    max_attempts = 5  # 最大5回まで試行
    
    max_attempts.times do |attempt|
      Rails.logger.info "[YouTube API] Attempt #{attempt + 1}/#{max_attempts}"
      
      # APIリクエスト
      items, next_page_token = fetch_videos_page(gender, intensity, max_results, page_token)
      
      # 結果を追加
      all_items.concat(items)
      
      # 重複を除去（videoIdで）
      unique_items = all_items.uniq { |item| item.dig("id", "videoId") }
      
      Rails.logger.info "[YouTube API] Total unique items so far: #{unique_items.size}"
      
      # 目標件数に達したら終了
      if unique_items.size >= target_count
        Rails.logger.info "[YouTube API] Target count reached: #{unique_items.size}"
        return unique_items.first(target_count)
      end
      
      # 次のページがない場合は終了
      if next_page_token.nil?
        Rails.logger.info "[YouTube API] No more pages available"
        break
      end
      
      page_token = next_page_token
    end
    
    Rails.logger.info "[YouTube API] Final result: #{all_items.uniq { |item| item.dig("id", "videoId") }.size} items"
    all_items.uniq { |item| item.dig("id", "videoId") }.first(target_count)
  end

  private

  def fetch_videos_page(gender, intensity, max_results, page_token = nil)
    uri = URI(BASE_URL)
    params = {
      key:           @api_key,
      part:          "snippet",
      type:          "video",
      q:             build_query(gender, intensity),
      videoDuration: "medium",
      maxResults:    max_results
    }
    
    # ページトークンがある場合は追加
    params[:pageToken] = page_token if page_token
    
    uri.query = params.to_query

    Rails.logger.info "[YouTube API] Request URL: #{uri}"
    raw = Net::HTTP.get(uri)
    Rails.logger.info "[YouTube API] Raw response body: #{raw}"

    json = JSON.parse(raw)
    if json["error"]
      Rails.logger.error "[YouTube API] Error: #{json["error"]["message"]}"
      return [], nil
    end

    items = json["items"] || []
    next_page_token = json["nextPageToken"]
    
    Rails.logger.info "[YouTube API] Items in this page: #{items.size}"
    Rails.logger.info "[YouTube API] Next page token: #{next_page_token}"

    # 各アイテムのvideoIdを詳細にログ出力
    items.each_with_index do |item, index|
      video_id = item.dig("id", "videoId")
      title = item.dig("snippet", "title")
      Rails.logger.info "[YouTube API] Item #{index + 1}: videoId=#{video_id}, title=#{title&.truncate(50)}"
    end

    # medium 以外も混じっていないかチェック
    valid = items.select { |i| i.dig("id","videoId").present? }
    Rails.logger.info "[YouTube API] Valid video items in this page: #{valid.size}"

    [valid, next_page_token]
  end

  KEYWORDS = {
    gender_intensity: {
      "man_low"    => "初心者 有酸素 トレーニング ダンス 家",
      "man_medium" => "自重トレーニング 家",
      "man_high"   => "HIIT トレーニング 家",
      "woman_low"  => "初心者 有酸素 トレーニング ダンス 家 簡単",
      "woman_medium" => "有酸素 トレーニング ダンス 家 ハード",
      "woman_high" => "有酸素 自重トレーニング 家",
      "other_low"  => "初心者 有酸素 トレーニング 家",
      "other_medium" => "有酸素 トレーニング 家",
      "other_high" => "HIIT トレーニング 家"
    }
  }

  def build_query(gender, intensity)
    key = "#{gender}_#{intensity}"
    KEYWORDS[:gender_intensity][key] || "workout training"
  end
end
