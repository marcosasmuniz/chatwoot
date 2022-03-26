class WppConnects::Events::Server::Onackes::Sent
  def self.call(wpp_connect, event)
    message_db = Message.find_by({'source_id': event['id']['_serialized']})

    if message_db
      return update_message(message_db, event)
    else
      return create_message(wpp_connect, event)
    end
  end

  def self.update_message(message_db, event)
    message_db.update({
      'source_id': event['id']['_serialized'],
      'external_source_ids': event
    })
    message_db
  end

  def self.find_or_create_contact(wpp_connect, event)
    phone = event['to'].split('@')[0]
    contact = Contact.find_by(phone_number: "+#{phone}")

    if contact == nil
      contact = Contact.create({
        account_id: wpp_connect.channel_api.account_id,
        phone_number: "+#{phone}",
        name: "#{event['notifyName']}",
        identifier: "#{event['to']}"
      })
    end
    contact
  end

  def self.create_message(wpp_connect, event)
    contact = find_or_create_contact(wpp_connect, event)
    conversation = find_or_create_new_conversation(wpp_connect, event, contact)

    Message.create(
      {
        'source_id': event['id']['_serialized'],
        'message_type': 'outgoing',
        'content': "#{event['body']}",
        'external_source_ids': event,
        'conversation_id': conversation.id,
        'inbox_id': wpp_connect.channel_api.inbox.id,
        'account_id': wpp_connect.channel_api.account.id
      }
    )
  end

  def self.find_or_create_new_conversation(wpp_connect, event, contact)
    conversation_id = "#{contact.identifier}_#{event['from']}"
    
    contact_inbox_params = {inbox_id: wpp_connect.channel_api.inbox.id, source_id: conversation_id, contact_id: contact.id}
    contact_inbox = ContactInbox.find_by(contact_inbox_params)
    if contact_inbox == nil
      contact_inbox = ContactInbox.create(contact_inbox_params)
    end
    
    conversation = Conversation.find_by({identifier: conversation_id, inbox_id: wpp_connect.channel_api.inbox.id, contact_id: contact.id})
    if conversation == nil
      conversation = Conversation.create({
        account_id: wpp_connect.channel_api.account.id,
        inbox_id: wpp_connect.channel_api.inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id,
        identifier: conversation_id
      })
    end
    conversation
  end
end
