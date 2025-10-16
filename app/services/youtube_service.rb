require "net/http"
require "uri"
require "json"

class YoutubeService
  BASE_URL = "https://www.googleapis.com/youtube/v3/search".freeze
  DEFAULT_TIMEOUT = 10 # seconds
  MAX_RETRY_ATTEMPTS = 3
  RETRY_WAIT_SECONDS = 1

  class ApiError < StandardError; end
  class TimeoutError < StandardError; end

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
    @keywords_config = load_keywords_config
  end

  def fetch_videos(gender:, intensity:, target_count: 5, max_results: 40)
    all_items = []
    page_token = nil
    max_attempts = 5  # 最大5回まで

    max_attempts.times do |_attempt|
      # APIリクエスト
      items, next_page_token = fetch_videos_page(gender, intensity, max_results, page_token)

      # 結果を追加
      all_items.concat(items)

      # 重複を除去（videoIdで）
      unique_items = all_items.uniq { |item| item.dig("id", "videoId") }

      # 目標件数に達したら終了
      return unique_items.first(target_count) if unique_items.size >= target_count

      # 次のページがない場合は終了
      break if next_page_token.nil?

      page_token = next_page_token
    end

    all_items.uniq { |item| item.dig("id", "videoId") }.first(target_count)
  rescue StandardError => e
    Rails.logger.error("YouTube API Error: #{e.message}")
    fallback_videos(target_count)
  end

  private

  def fetch_videos_page(gender, intensity, max_results, page_token = nil)
    uri = build_request_uri(gender, intensity, max_results, page_token)

    response_json = execute_api_request(uri)

    # APIエラーチェック
    return [[], nil] if response_json["error"]

    items = response_json["items"] || []
    next_page_token = response_json["nextPageToken"]

    # 有効な動画のみをフィルタ
    valid_items = items.select { |i| i.dig("id", "videoId").present? }

    [valid_items, next_page_token]
  end

  def build_request_uri(gender, intensity, max_results, page_token)
    uri = URI(BASE_URL)
    params = {
      key:           @api_key,
      part:          "snippet",
      type:          "video",
      q:             build_query(gender, intensity),
      videoDuration: "medium",
      maxResults:    max_results
    }

    params[:pageToken] = page_token if page_token

    uri.query = params.to_query
    uri
  end

  def execute_api_request(uri)
    MAX_RETRY_ATTEMPTS.times do |attempt|
      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                    open_timeout: DEFAULT_TIMEOUT,
                                    read_timeout: DEFAULT_TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end

        return JSON.parse(response.body)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise TimeoutError, "YouTube API timeout: #{e.message}" if attempt == MAX_RETRY_ATTEMPTS - 1

        Rails.logger.warn("YouTube API timeout, retrying... (#{attempt + 1}/#{MAX_RETRY_ATTEMPTS})")
        sleep(RETRY_WAIT_SECONDS)
      rescue StandardError => e
        raise ApiError, "YouTube API request failed: #{e.message}" if attempt == MAX_RETRY_ATTEMPTS - 1

        Rails.logger.warn("YouTube API error, retrying... (#{attempt + 1}/#{MAX_RETRY_ATTEMPTS}): #{e.message}")
        sleep(RETRY_WAIT_SECONDS)
      end
    end
  end

  def build_query(gender, intensity)
    key = "#{gender}_#{intensity}"
    @keywords_config.dig("gender_intensity", key) || fallback_keyword
  end

  def load_keywords_config
    config_path = Rails.root.join("config", "youtube_keywords.yml")
    yaml_content = YAML.load_file(config_path)
    yaml_content[Rails.env] || yaml_content["default"]
  rescue StandardError => e
    Rails.logger.error("Failed to load YouTube keywords config: #{e.message}")
    # デフォルト設定を返す
    {
      "gender_intensity" => {},
      "fallback" => "workout training"
    }
  end

  def fallback_keyword
    @keywords_config["fallback"] || "workout training"
  end

  def fallback_videos(_target_count)
    # フォールバック動画（APIエラー時）
    # 実際の実装では、デフォルトの動画リストやキャッシュデータを返すことができます
    Rails.logger.warn("Returning empty array due to API error")
    []
  end
end
