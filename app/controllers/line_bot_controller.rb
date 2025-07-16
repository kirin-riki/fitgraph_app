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
      LineBotService.new(event).handle_event
    end
    head :ok
  end
end
