class Integrations::WppConnects::EventsJob < ApplicationJob
  queue_as :low

  def perform(event_json)
    event = JSON.parse(event_json)

    if event['event'] == 'onmessage'
      return message_event(event)
    elsif event['event'] == 'onack'
      return onack_event(event)
    end
  end

  private

  def message_event(event)
    wpp_connect = WppConnect.find(event['wpp_connect_id'])
    WppConnects::Events::Server::Message.call(wpp_connect, event)
  end

  def onack_event(event)
    wpp_connect = WppConnect.find(event['wpp_connect_id'])
    WppConnects::Events::Server::Onack.call(wpp_connect, event)
  end
end
