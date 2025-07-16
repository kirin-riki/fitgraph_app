class LineBotService
  def initialize(event)
    @event = event
  end

  def handle_event
    return unless @event.is_a?(Line::Bot::Event::Message) && @event.message["type"] == "text"
    user = User.find_by(line_user_id: @event["source"]["userId"])
    if user && user.uid.present?
      handle_user_message(user)
    else
      reply_message(@event["replyToken"], { type: "text", text: "この機能を利用するにはマイページでLINE連携が必要です。" })
    end
  end

  private

  def handle_user_message(user)
    text = @event.message["text"].strip
    case text
    when "通知"
      reply_message(@event["replyToken"], quick_reply_message)
    when /\A\d{1,2}:\d{2}\z/
      target_time = Time.current.change(hour: text.split(":")[0].to_i, min: text.split(":")[1].to_i)
      NotificationJob.set(wait_until: target_time).perform_later(user.id)
      reply_message(@event["replyToken"], { type: "text", text: "通知を予約しました" })
    when "リスケ"
      reply_message(@event["replyToken"], { type: "text", text: "新しい通知時刻を入力してください（例: 12:00）" })
    when "通知取り消し"
      # ここでNotificationJobのキャンセル処理を実装（必要に応じて）
      reply_message(@event["replyToken"], { type: "text", text: "通知を解除しました" })
    else
      # リスケ状態の管理は不要。時刻入力があれば予約し直す。
      if text =~ /\A\d{1,2}:\d{2}\z/
        target_time = Time.current.change(hour: text.split(":")[0].to_i, min: text.split(":")[1].to_i)
        NotificationJob.set(wait_until: target_time).perform_later(user.id)
        reply_message(@event["replyToken"], { type: "text", text: "通知時間を変更しました" })
      end
    end
  end

  def reply_message(token, message)
    res = LineClient.client.reply_message(token, message)
    Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
  end

  def quick_reply_message
    {
      type: "text",
      text: "通知時刻を入力してください（例: 12:00）"
    }
  end
end
