class LineBotController < ApplicationController
  skip_before_action :verify_authenticity_token

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    events = LineClient.parse_events(body, signature)

    events.each do |event|
      if event['type'] == 'message' && event['message']['type'] == 'text'
        handle_text_message(event)
      end
    end

    head :ok
  end

  private

  def handle_text_message(event)
    user_id = event['source']['userId']
    text = event['message']['text']

    case text
    when '通知'
      send_notification_quick_reply(event['replyToken'])
    when /^(\d{1,2}):(\d{2})$/
      handle_time_selection(user_id, $1, $2, event['replyToken'])
    else
      send_help_message(event['replyToken'])
    end
  end

  def send_notification_quick_reply(reply_token)
    messages = {
      type: 'text',
      text: '通知時刻を選択してください',
      quickReply: {
        items: generate_time_options
      }
    }

    LineClient.reply_message(reply_token, messages)
  end

  def generate_time_options
    times = []
    
    # 6:00から22:00まで30分間隔で時刻オプションを生成
    (6..22).each do |hour|
      [0, 30].each do |minute|
        time_str = "#{hour.to_s.rjust(2, '0')}:#{minute.to_s.rjust(2, '0')}"
        times << {
          type: 'action',
          action: {
            type: 'message',
            label: time_str,
            text: time_str
          }
        }
      end
    end

    times
  end

  def handle_time_selection(user_id, hour, minute, reply_token)
    target_time = Time.current.change(hour: hour.to_i, min: minute.to_i)
    
    # 過去の時刻の場合は翌日に設定
    if target_time <= Time.current
      target_time = target_time + 1.day
    end

    # ジョブを登録
    NotificationJob.set(wait_until: target_time).perform_later(user_id)

    message = "今日の#{hour}:#{minute}に通知を設定しました！"
    LineClient.reply_message(reply_token, { type: 'text', text: message })
  end

  def send_help_message(reply_token)
    message = "「通知」と送信すると時刻選択ができます。\nまたは「HH:MM」の形式で直接時刻を指定することもできます。"
    LineClient.reply_message(reply_token, { type: 'text', text: message })
  end
end
