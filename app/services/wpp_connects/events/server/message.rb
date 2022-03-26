class WppConnects::Events::Server::Message
  def self.call(wpp_connect, event)
    if sync_message?(event)
      return sync_message(wpp_connect, event)
    end
  end

  def self.sync_message(wpp_connect, event)
    if event['fromMe'] == false
      return WppConnects::Events::Server::Messages::Receive.call(wpp_connect, event)
    end
  end

  def self.sync_message?(event)
    event['type'] == 'chat'
  end
end
