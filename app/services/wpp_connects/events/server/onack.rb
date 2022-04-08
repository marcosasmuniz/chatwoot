class WppConnects::Events::Server::Onack
  def self.call(wpp_connect, event)
    event = WppConnects::Events::Server::Messages::MessageEvent.call(event)
    if WppConnects::Events::Server::Message.sync_message?(event)
      return sync_message(wpp_connect, event)
    end
  end

  def self.sync_message(wpp_connect, event)
    if event['fromMe'] == true
      return WppConnects::Events::Server::Onackes::Sent.call(wpp_connect, event)
    end
  end
end
