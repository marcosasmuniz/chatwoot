class WppConnects::SyncService
  include WppConnects::Sync::Conversation
  include WppConnects::Sync::Chats

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

  def update_sync_status(chat, conversation)
    @wpp_connect.update(status_sync:  @wpp_connect.status_sync.merge({'last_sync': {'last_key_time': Time.at(chat['t']), 'current_time': DateTime.now, 'chat': chat}}))
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
