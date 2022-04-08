class WppConnects::Events::Server::Onackes::Sent
  def self.call(wpp_connect, event)
    message_db = Message.find_by({'source_id': event['id']})

    if message_db
      return update_message(message_db, event)
    else
      return WppConnects::Events::Server::Message.create_message(wpp_connect, event)
    end
  end

  def self.update_message(message_db, event)
    message_db.update({
      'source_id': event['id'],
      'external_source_ids': event
    })
    message_db
  end
end
