class NotificationJob < ApplicationJob
  def perform(user_id)
    Rails.logger.info "=== NotificationJob開始！ user_id: #{user_id} ==="
    user = User.find(user_id)
    response = LineClient.client.push_message(user.line_user_id, { type: "text", text: "リマインド通知です！" })
    Rails.logger.info "=== Push送信完了 response: #{response.code} ==="
  end
end
