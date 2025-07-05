class NotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    LineClient.client.push_message(user.line_user_id, { type: 'text', text: 'リマインド通知です！' })
  end
end 