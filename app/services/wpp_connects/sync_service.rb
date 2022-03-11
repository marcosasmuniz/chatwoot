class WppConnects::SyncService

  def initialize(wpp_connect)
    @wpp_connect = wpp_connect
  end

  def call()
    refresh_connection()
    chats = get_chats()
    sync_chats(chats)
    true
  end

  def refresh_connection()
    response = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/host-device",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
    )
    result = response.parsed_response['response'] rescue nil
    if (result == nil)
      @wpp_connect.status_sync = @wpp_connect.status_sync.merge({'wpp': {'status': 'disconnected'}})
    else
      is_mid = result['clientToken'].blank?
      @wpp_connect.status_sync = @wpp_connect.status_sync.merge({'wpp': {'status': 'connected', 'is_md': is_mid}})
    end
    @wpp_connect.save
    
    raise "WppConnectionComunication" if result == nil
  end

  def get_chats()
    response = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/all-chats",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
    )
    result = response.parsed_response['response'].reverse() rescue nil
    result
  end

  def sync_chats(chats)
    chats.each do | chat |
      if sync_chat?(chat)
        contact = sync_contact(chat)
        update_sync_status(chat) if sync_messages(contact)
      end
    end
  end

  def update_sync_status(chat)
    @wpp_connect.update(status_sync:  @wpp_connect.status_sync.merge({'last_sync': {'last_key_time': Time.at(chat['t']), 'current_time': DateTime.now, 'chat': chat}}))
  end

  def sync_contact(chat)
    contact = Contact.find_by(phone_number: "+#{chat['id']['user']}" )
    if contact == nil
      contact_id = Contact.insert({
        account_id: @wpp_connect.channel_api.account_id,
        phone_number: "+#{chat['id']['user']}",
        name: "#{chat['contact']['name']}",
        identifier: "#{chat['id']['_serialized']}",
        created_at: DateTime.now,
        updated_at: DateTime.now,
      }).rows.first.first
      contact = Contact.find(contact_id)
    end
    contact
  end

  def sync_messages(contact)
    messages = get_messages(contact)
    if messages.key?(:error)
      puts("Falha ao sincronizar contato #{contact.inspect} ") 
      return false
    end 

    conversation_id = "#{contact.identifier}_#{my_id()}"
    
    contact_inbox_params = {inbox_id: @wpp_connect.channel_api.inbox.id, source_id: conversation_id, contact_id: contact.id}
    contact_inbox = ContactInbox.find_by(contact_inbox_params)
    if contact_inbox == nil
      contact_inbox_id = ContactInbox.insert(contact_inbox_params.merge({created_at: Time.at(messages[:ok].first['timestamp']), updated_at: Time.at(messages[:ok].first['timestamp']) })).rows.first.first
      contact_inbox = ContactInbox.find(contact_inbox_id)
    end
    
    conversation = Conversation.find_by({identifier: conversation_id})
    if conversation == nil
      conversation_id = Conversation.insert(
        {
          account_id: @wpp_connect.channel_api.account.id,
          inbox_id: @wpp_connect.channel_api.inbox.id,
          contact_id: contact.id,
          contact_inbox_id: contact_inbox.id,
          identifier: conversation_id,
          status: open_conversation?(messages[:ok].last)
        }.merge({created_at: Time.at(messages[:ok].last['timestamp']), updated_at: Time.at(messages[:ok].last['timestamp'])})
      ).rows.first.first
      conversation = Conversation.find(conversation_id)
    end
    

    messages[:ok].each do | message |
      message_db = Message.find_by({'source_id': message['id']})
      if message_db == nil
        message_db_id = Message.insert(
          {
            'source_id': message['id'],
            'message_type': message_type(message),
            'content': "#{message['body']}",
            'external_source_ids': message,
            'conversation_id': conversation.id,
            'inbox_id': @wpp_connect.channel_api.inbox.id,
            'account_id': @wpp_connect.channel_api.account.id,
            'created_at': Time.at(message['timestamp']),
            'updated_at': Time.at(message['timestamp'])
          }
        ).rows.first.first
        message_db = Message.find(message_db_id)
      else message_db.external_source_ids.blank?
        message_db.update_columns({
          'source_id': message['id'],
          'message_type': message_type(message),
          'content': "#{message['body']}",
          'external_source_ids': message,
          'conversation_id': conversation.id,
          'inbox_id': @wpp_connect.channel_api.inbox.id,
          'account_id': @wpp_connect.channel_api.account.id,
          'updated_at': Time.at(message['timestamp'])
        })
      end
    end

    puts("Sincronizado contato #{conversation_id} mensagens #{messages[:ok].count}")
    return true
  end

  def message_type(message)
    if message['fromMe'] == true
      return 'outgoing'
    else
      return 'incoming'
    end
  end

  def get_messages_normal_wpp(contact)
    response = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/load-messages-in-chat/#{contact.identifier.split('@')[0]}",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' },
      timeout: 10      
    )
    
    if response.parsed_response['status'] == 'success' && response.parsed_response['response'].present?
      return {ok: response.parsed_response['response']} 
    else
      return { error: response.parsed_response}
    end
  end

  def get_messages_md_wpp(contact)
    response = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/chat-by-id/#{contact.identifier.split('@')[0]}",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' },
      timeout: 10
    )
    
    if response.parsed_response['status'] == 'success' && response.parsed_response['response'].present?
      return {ok: response.parsed_response['response']} 
    else
      return { error: response.parsed_response}
    end
  end

  def get_messages(contact)
    if @wpp_connect.status_sync['wpp']['is_md'] == true
      return get_messages_md_wpp(contact)
    else
      return get_messages_normal_wpp(contact)
    end
  end

  def sync_chat?(chat)
    if is_not_group_chat?(chat) && chat_have_messages(chat) && is_not_sincronized?(chat)
      return true
    else
      return false
    end
  end

  def is_not_sincronized?(chat)
    @wpp_connect.status_sync['last_sync'].blank? || @wpp_connect.status_sync['last_sync']['last_key_time'] < Time.at(chat['t'])
  end

  def chat_have_messages(chat)
    chat['t'].present?
  end

  def is_not_group_chat?(chat)
    chat['kind'] == 'chat' && chat['isUser'] == true
  end

  def open_conversation?(last_message)
    return 'resolved'
  end

  def older?(datetime)
    datetime < @wpp_connect.created_at
  end

  def my_id()
    if @my_id.blank?
      response = HTTParty.get(
        "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/host-device",
        headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
      )
      result = response.parsed_response['response'] rescue nil
  
      @my_id = result['phoneNumber']
    else
      return @my_id
    end
  end
end
