module WppConnects::Sync::Messages
  def sync_new_messages()
    @messages[:ok].each do | message |
      next if sync_message?(message) == false

      if older?(Time.at(message['timestamp']))
        sync_old_message(message)
      else
        sync_new_message(message)
      end
    end

    puts("Sincronizado contato #{@contact.phone_number} mensagens #{@messages[:ok].count}")
    true
  end

  def sync_old_messages(contact)
    @messages[:ok].each do | message |
      next if sync_message?(message) == false

      message_db = Message.find_by({'source_id': message['id']})
      if message_db == nil
        message_db_id = Message.insert(
          {
            'source_id': message['id'],
            'message_type': message_type(message),
            'content': "#{message['body']}",
            'external_source_ids': message,
            'conversation_id': @conversation.id,
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
          'conversation_id': @conversation.id,
          'inbox_id': @wpp_connect.channel_api.inbox.id,
          'account_id': @wpp_connect.channel_api.account.id,
          'updated_at': Time.at(message['timestamp'])
        })
      end
    end

    puts("Sincronizado contato #{contact.phone_number} mensagens #{@messages[:ok].count}")
    return true
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
    # if @wpp_connect.status_sync['wpp']['is_md'] == true
    #   return get_messages_md_wpp(contact)
    # else
    #   return get_messages_normal_wpp(contact)
    # end
    return get_messages_md_wpp(contact)
  end
end