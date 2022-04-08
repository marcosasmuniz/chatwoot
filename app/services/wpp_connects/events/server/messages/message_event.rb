class WppConnects::Events::Server::Messages::MessageEvent
  def self.call(event)
    if (event['event'] == 'onack')
      return WppConnects::Events::Server::Messages::OnackAdapter.call(event)
    end

    event
  end
end
