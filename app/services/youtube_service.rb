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
      # APIリクエスト
      items, next_page_token = fetch_videos_page(gender, intensity, max_results, page_token)
      
      # 結果を追加
      all_items.concat(items)
      
      # 重複を除去（videoIdで）
      unique_items = all_items.uniq { |item| item.dig("id", "videoId") }
      
      # 目標件数に達したら終了
      if unique_items.size >= target_count
        return unique_items.first(target_count)
      end
      
      # 次のページがない場合は終了
      if next_page_token.nil?
        break
      end
      
      page_token = next_page_token
    end
    
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

    raw = Net::HTTP.get(uri)

    json = JSON.parse(raw)
    if json["error"]
      return [], nil
    end

    items = json["items"] || []
    next_page_token = json["nextPageToken"]

    # medium 以外も混じっていないかチェック
    valid = items.select { |i| i.dig("id","videoId").present? }

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
