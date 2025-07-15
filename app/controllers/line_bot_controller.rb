class LineBotController < ApplicationController
  protect_from_forgery except: :callback

  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless LineClient.client.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = LineClient.client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        if event.message["type"] == "text"
          user = User.find_by(line_user_id: event["source"]["userId"])
          if user && user.uid.present?
            case event.message["text"].strip
            when "通知"
              res = LineClient.client.reply_message(event["replyToken"], quick_reply_message)
              Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
            when /\A\d{1,2}:\d{2}\z/
              target_time = Time.current.change(hour: event.message["text"].split(":")[0].to_i, min: event.message["text"].split(":")[1].to_i)
              NotificationJob.set(wait_until: target_time).perform_later(user.id)
              res = LineClient.client.reply_message(event["replyToken"], { type: "text", text: "通知を予約しました" })
              Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
            when "リスケ"
              res = LineClient.client.reply_message(event["replyToken"], { type: "text", text: "新しい通知時刻を入力してください（例: 12:00）" })
              Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
            when "通知取り消し"
              # ここでNotificationJobのキャンセル処理を実装（必要に応じて）
              res = LineClient.client.reply_message(event["replyToken"], { type: "text", text: "通知を解除しました" })
              Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
            else
              # リスケ状態の管理は不要。時刻入力があれば予約し直す。
              if event.message["text"].strip =~ /\A\d{1,2}:\d{2}\z/
                target_time = Time.current.change(hour: event.message["text"].split(":")[0].to_i, min: event.message["text"].split(":")[1].to_i)
                NotificationJob.set(wait_until: target_time).perform_later(user.id)
                res = LineClient.client.reply_message(event["replyToken"], { type: "text", text: "通知時間を変更しました" })
                Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
              end
            end
          else
            res = LineClient.client.reply_message(event["replyToken"], { type: "text", text: "この機能を利用するにはマイページでLINE連携が必要です。" })
            Rails.logger.info "LINE reply response: \\#{res.body} (\\#{res.code})"
          end
        end
      end
    end
    head :ok
  end

  private

  def quick_reply_message
    {
      type: "text",
      text: "通知時刻を入力してください（例: 12:00）"
    }
  end
end
