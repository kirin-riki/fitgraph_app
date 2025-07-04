class NotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, message = "通知時間になりました！")
    LineClient.push_message(user_id, {
      type: 'text',
      text: message
    })
  rescue => e
    Rails.logger.error "LINE通知送信エラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end 