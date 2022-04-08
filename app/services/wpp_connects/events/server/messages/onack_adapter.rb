class WppConnects::Events::Server::Messages::OnackAdapter
  def self.call(event)
    new_event = event
    new_event['fromMe'] = event['id']['fromMe']
    new_event['id'] = event['id']['_serialized']
    new_event
  end
end
