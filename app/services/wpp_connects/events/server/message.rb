class WppConnects::Events::Server::Message
  def self.call(wpp_connect, event)
    event = WppConnects::Events::Server::Messages::MessageEvent.call(event)
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
    event['type'] == 'chat' || event['type'] == 'image' || event['type'] == 'document' || event['type'] == 'ptt' || event['type'] == 'video' || event['type'] == 'audio'
  end

  def self.file_event_types
    ['image', 'document', 'ptt', 'video', 'audio', 'in', 'sticker']
  end

  def self.file_event?(event)
    file_event_types.include?(event['type'])
  end

  def self.message_type(event)
    event['fromMe'] == true ? 'outgoing' : 'incoming'
  end

  def self.find_or_create_contact(wpp_connect, event)
    if event['fromMe'] == true
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
    else
      phone = event['from'].split('@')[0]
      contact = Contact.find_by(phone_number: "+#{phone}")

      if contact == nil
        contact = Contact.create({
          account_id: wpp_connect.channel_api.account_id,
          phone_number: "+#{phone}",
          name: "#{event['notifyName']}",
          identifier: "#{event['from']}"
        })
      end
    end

    contact
  end

  def self.find_or_create_new_conversation(wpp_connect, event, contact)
    if event['fromMe'] == true
      conversation_id = "#{contact.identifier}_#{event['from']}"
    
      contact_inbox_params = {inbox_id: wpp_connect.channel_api.inbox.id, contact_id: contact.id}
      contact_inbox = ContactInbox.find_by(contact_inbox_params)
      if contact_inbox == nil
        contact_inbox = ContactInbox.create(contact_inbox_params)
      end
      
      conversation = Conversation.find_by({inbox_id: wpp_connect.channel_api.inbox.id, contact_id: contact.id})
      if conversation == nil
        conversation = Conversation.create({
          account_id: wpp_connect.channel_api.account.id,
          inbox_id: wpp_connect.channel_api.inbox.id,
          contact_id: contact.id,
          contact_inbox_id: contact_inbox.id,
          identifier: conversation_id
        })
      end
    else
      conversation_id = "#{contact.identifier}_#{event['to']}"
    
      contact_inbox_params = {inbox_id: wpp_connect.channel_api.inbox.id, contact_id: contact.id}
      contact_inbox = ContactInbox.find_by(contact_inbox_params)
      if contact_inbox == nil
        contact_inbox = ContactInbox.create(contact_inbox_params)
      end
      
      conversation = Conversation.find_by({inbox_id: wpp_connect.channel_api.inbox.id, contact_id: contact.id})
      if conversation == nil
        conversation = Conversation.create({
          account_id: wpp_connect.channel_api.account.id,
          inbox_id: wpp_connect.channel_api.inbox.id,
          contact_id: contact.id,
          contact_inbox_id: contact_inbox.id,
          identifier: conversation_id
        })
      end
    end

    conversation
  end

  def self.create_message(wpp_connect, event)
    contact = find_or_create_contact(wpp_connect, event)
    conversation = find_or_create_new_conversation(wpp_connect, event, contact)
    message = Message.new(
      {
        'source_id': event['id'],
        'message_type': message_type(event),
        'external_source_ids': event,
        'conversation_id': conversation.id,
        'inbox_id': wpp_connect.channel_api.inbox.id,
        'account_id': wpp_connect.channel_api.account.id
      }
    )

    if file_event?(event)
      decoded_data = Base64.decode64(event['body'])
      attachment = Attachment.new.file = { 
        io: StringIO.new(decoded_data),
        content_type: event['mimetype'],
        filename: "file.#{event['mimetype'].split('/')[1]}"
      }
      message.attachments.build(
        account_id: wpp_connect.channel_api.account.id,
        file: attachment
      )
    elsif event['type'] == 'chat'
      message.content = "#{event['body']}"
    end
    message.save

    message
  end
end
