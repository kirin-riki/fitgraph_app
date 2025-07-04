require 'line/bot'

class LineClient
  class << self
    def parser
      @parser ||= Line::Bot::V2::WebhookParser.new(channel_secret: ENV['LINE_CHANNEL_SECRET'])
    end

    def client
      @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(channel_token: ENV['LINE_CHANNEL_TOKEN'])
    end

    def parse_events(body, signature)
      parser.parse(body, signature)
    end

    def reply_message(reply_token, messages)
      client.reply_message(reply_token: reply_token, messages: [messages])
    end

    def push_message(user_id, messages)
      client.push_message(to: user_id, messages: [messages])
    end

    def get_profile(user_id)
      client.get_profile(user_id: user_id)
    end
  end
end 