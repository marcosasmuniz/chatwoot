module WppConnects::Sync::Conversation
  include WppConnects::Sync::Contact
  include WppConnects::Sync::Messages
  include WppConnects::Sync::Message

  def sync_old_conversation(chat)
    @contact = sync_old_contact(chat)
    @conversation = find_or_create_old_conversation(chat, @contact)
    return if conversation_is_sincronized?(@conversation, chat)

    @messages = get_messages(@contact)
    if @messages.key?(:error)
      puts("Falha ao sincronizar contato #{@contact.phone_number}") 
      return false
    end 
    if sync_old_messages(@contact)
      update_conversation(@conversation, chat)
      update_sync_status(chat, @conversation)
    end
  end

  def sync_new_conversation(chat)
    @contact = sync_new_contact(chat)
    @conversation = find_or_create_new_conversation(chat, @contact)
    return if conversation_is_sincronized?(@conversation, chat)

    @messages = get_messages(@contact)
    if @messages.key?(:error)
      puts("Falha ao sincronizar contato #{@contact.phone_number}") 
      return false
    end
    if sync_new_messages()
      update_conversation(@conversation, chat)
      update_sync_status(chat, @conversation)
    end
  end

  def update_conversation(conversation, chat)
    conversation.update_columns({additional_attributes: { last_message: Time.at(chat['t']) }})
    conversation.update(status: 'open') unless older_conversation?(chat)
  end

  def older_conversation?(chat)
    older?(Time.at(chat['t']))
  end

  def find_or_create_new_conversation(chat, contact)
    conversation_id = "#{contact.identifier}_#{my_id()}"
    
    contact_inbox_params = {inbox_id: @wpp_connect.channel_api.inbox.id, contact_id: contact.id}
    contact_inbox = ContactInbox.find_by(contact_inbox_params)
    if contact_inbox == nil
      contact_inbox = ContactInbox.create(contact_inbox_params)
    end
    
    conversation = Conversation.find_by({inbox_id: @wpp_connect.channel_api.inbox.id, contact_id: contact.id})
    if conversation == nil
      conversation = Conversation.create({
        account_id: @wpp_connect.channel_api.account.id,
        inbox_id: @wpp_connect.channel_api.inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id,
        identifier: conversation_id
      })
    end
    conversation
  end

  def find_or_create_old_conversation(chat, contact)
    conversation_id = "#{contact.identifier}_#{my_id()}"
    
    contact_inbox_params = {inbox_id: @wpp_connect.channel_api.inbox.id, contact_id: contact.id}
    contact_inbox = ContactInbox.find_by(contact_inbox_params)
    if contact_inbox == nil
      contact_inbox_id = ContactInbox.insert(contact_inbox_params.merge({created_at: Time.at(chat['t']), updated_at: Time.at(chat['t']) })).rows.first.first
      contact_inbox = ContactInbox.find(contact_inbox_id)
    end
    
    conversation = Conversation.find_by({inbox_id: @wpp_connect.channel_api.inbox.id, contact_id: contact.id})
    if conversation == nil
      conversation_id = Conversation.insert(
        {
          account_id: @wpp_connect.channel_api.account.id,
          inbox_id: @wpp_connect.channel_api.inbox.id,
          contact_id: contact.id,
          contact_inbox_id: contact_inbox.id,
          identifier: conversation_id,
          status: 'resolved'
        }.merge({created_at: Time.at(chat['t']), updated_at: Time.at(chat['t'])})
      ).rows.first.first
      conversation = Conversation.find(conversation_id)
    end
    conversation
  end

  def conversation_is_sincronized?(conversation, chat)
    conversation.additional_attributes['last_message'].present? && Time.at(chat['t']) == DateTime.parse(conversation.additional_attributes['last_message']) 
  end
end