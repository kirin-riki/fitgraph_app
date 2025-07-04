class LineClient
  class << self
    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV['LINE_CHANNEL_SECRET']
        config.channel_access_token = ENV['LINE_CHANNEL_TOKEN']
      end
    end

    def validate_signature(body, signature)
      client.validate_signature(body, signature)
    end

    def reply_message(reply_token, messages)
      client.reply_message(reply_token, messages)
    end

    def push_message(user_id, messages)
      client.push_message(user_id, messages)
    end

    def get_profile(user_id)
      client.get_profile(user_id)
    end
  end
end 