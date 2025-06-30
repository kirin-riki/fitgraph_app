class YoutubeApiService
  require 'net/http'
  require 'json'

  def initialize
    @api_key = ENV['YOUTUBE_API_KEY'] || Rails.application.credentials.youtube_api_key
    @base_url = 'https://www.googleapis.com/youtube/v3'
    Rails.logger.info "YouTube API Service initialized. API key present: #{@api_key.present?}"
  end

  def fetch_video_info(video_id)
    unless @api_key.present?
      Rails.logger.warn "YouTube API key is not configured"
      return {}
    end

    begin
      url = "#{@base_url}/videos?part=snippet&id=#{video_id}&key=#{@api_key}"
      Rails.logger.info "Making YouTube API request to: #{@base_url}/videos?part=snippet&id=#{video_id}&key=[HIDDEN]"
      
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      Rails.logger.info "YouTube API response code: #{response.code}"

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        Rails.logger.info "YouTube API response data: #{data}"
        
        items = data['items']
        
        if items.present?
          snippet = items.first['snippet']
          result = {
            title: snippet['title'],
            channel_title: snippet['channelTitle'],
            thumbnail_url: snippet['thumbnails']['default']['url'],
            published_at: snippet['publishedAt']
          }
          Rails.logger.info "Successfully extracted video info: #{result}"
          result
        else
          Rails.logger.warn "No items found in YouTube API response"
          {}
        end
      else
        Rails.logger.error "YouTube API error: #{response.code} - #{response.body}"
        {}
      end
    rescue => e
      Rails.logger.error "YouTube API request failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {}
    end
  end

  def self.fetch_video_info(video_id)
    new.fetch_video_info(video_id)
  end
end 