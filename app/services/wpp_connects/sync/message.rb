module WppConnects::Sync::Message
  def sync_new_message(message)
    message_db = Message.find_by({'source_id': message['id']})
    if message_db == nil
      message_db = Message.create(
        {
          'source_id': message['id'],
          'message_type': message_type(message),
          'content': "#{message['body']}",
          'external_source_ids': message,
          'conversation_id': @conversation.id,
          'inbox_id': @wpp_connect.channel_api.inbox.id,
          'account_id': @wpp_connect.channel_api.account.id
        }
      )
    else message_db.external_source_ids.blank?
      message_db.update({
        'source_id': message['id'],
        'message_type': message_type(message),
        'content': "#{message['body']}",
        'external_source_ids': message,
        'conversation_id': @conversation.id,
        'inbox_id': @wpp_connect.channel_api.inbox.id,
        'account_id': @wpp_connect.channel_api.account.id
      })
    end
  end

  def sync_old_message(message)
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

  def message_type(message)
    if message['fromMe'] == true
      return 'outgoing'
    else
      return 'incoming'
    end
  end

  def sync_message?(message)
    message['type'] != 'e2e_notification'
  end
end