class WppConnects::Events::Server::Onack
  def self.call(wpp_connect, event)
    if sync_message?(event)
      return sync_message(wpp_connect, event)
    end
  end

  def self.sync_message(wpp_connect, event)
    if event['id']['fromMe'] == true
      return WppConnects::Events::Server::Onackes::Sent.call(wpp_connect, event)
    end
  end

  def self.sync_message?(event)
    event['type'] == 'chat'
  end
end
