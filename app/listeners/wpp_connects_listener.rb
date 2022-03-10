class WppConnectsListener < BaseListener
  def message_created(event)
    WppConnects::Chatwoot::Events::Messages::Created.call(event)
  end
end
