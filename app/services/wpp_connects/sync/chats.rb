module WppConnects::Sync::Chats

  def sync_chats(chats)
    chats.each do | chat |
      if valid_chat?(chat)
        if older_conversation?(chat)
          sync_old_conversation(chat)
        else
          sync_new_conversation(chat)
        end
      end
    end
  end

  def valid_chat?(chat)
    if is_not_group_chat?(chat) && chat_have_messages(chat)
      return true
    else
      return false
    end
  end

  def chat_have_messages(chat)
    chat['t'].present?
  end

  def is_not_group_chat?(chat)
    chat['kind'] == 'chat' && chat['isUser'] == true
  end

  def get_chats()
    response = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/all-chats",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
    )
    result = response.parsed_response['response'].reverse() rescue nil
    result
  end
end