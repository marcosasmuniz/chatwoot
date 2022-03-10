class WppConnects::Chatwoot::Events::Messages::Created
  def self.call(event)
    if delivery_message?(event)
      send_message(event)
    end
  end

  def self.delivery_message?(event)
    puts(
      "
      #{event.data[:message].source_id.blank? == true}
      #{event.name == 'message.created'}
      #{event.data[:message].message_type == 'outgoing'}
      #{event.data[:message].private? == false}
      #{event.data[:message].inbox.api?}
      #{event.data[:message].inbox.channel.wpp_connect.present?}
      #{event.data[:message].contact.blank?}
      "
    )


    result = event.data[:message].source_id.blank? == true && 
    event.name == 'message.created' && 
    event.data[:message].message_type == 'outgoing' && 
    event.data[:message].private? == false &&
    event.data[:message].inbox.api?
    event.data[:message].inbox.channel.wpp_connect.present? &&
    event.data[:message].user.present?
    puts("Resultado #{result}")
    return result
  end

  def self.send_message(event)
    message = event.data[:message]
    wpp_connect = event.data[:message].inbox.channel.wpp_connect
    contact = event.data[:message].conversation.contact

    begin
      response = HTTParty.post(
        "#{wpp_connect.wppconnect_endpoint}/api/#{wpp_connect.wppconnect_session}/send-message",
        headers: { 'Authorization' => "Bearer #{wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' },
        body: {
          "phone": "#{contact.phone_number.split('+')[1]}",
          "message": "#{message.content}",
          "isGroup": false
        }.to_json
      )
  
      p "Resposta da request"
      p response.inspect
      p "#{contact.phone_number.split('+')[1]}"
  
      message_wpp = response.parsed_response['response'][0] rescue nil
      message_wpp_id = message_wpp['id'] rescue nil
      p "message"
      p message.inspect
      if (message_wpp_id.present?)
        message.update(source_id: message_wpp_id)
        return true
      else
        message.update(status: 'failed')
        return false
      end
    rescue => exception
      message.update(status: 'failed')
    end
  end
end
