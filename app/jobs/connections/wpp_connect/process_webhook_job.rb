class Connections::WppConnect::ProcessWebhookJob < ApplicationJob
  def perform(params)
    event_hash = JSON.parse(params)
    if (receive_message?(event_hash))
      @connection = Connection.find(event_hash['connection_id'])
      contact = get_contact(event_hash)
      conversation = get_conversation(contact)
      message = send_message_to_chatwoot(conversation, event_hash)
      p "Resultado"
      p message.inspect
      return {ok: message}
    end
  end

  def send_message_to_chatwoot(conversation, event_hash)
    response = Faraday.post(
      "#{@connection.chatwoot_endpoint}/api/v1/accounts/#{@connection.chatwoot_account_id}/conversations/#{conversation['id']}/messages",
      {
        "content": "#{event_hash['content']}",
        "message_type": "incoming",
        "source_id": "#{event_hash['id']}",
        "external_source_ids": event_hash
      }.to_json,
      { 'Content-Type': "application/json", "api_access_token": "#{@connection.chatwoot_account_token}" }
    )
    return JSON.parse(response.body)
  end

  def get_conversation(contact)
    response = Faraday.get(
      "#{@connection.chatwoot_endpoint}/api/v1/accounts/#{@connection.chatwoot_account_id}/contacts/#{contact['id']}/conversations",
      {},
      { 'Content-Type': "application/json", "api_access_token": "#{@connection.chatwoot_account_token}" }
    )
    return JSON.parse(response.body)['payload'][0]
  end

  def get_contact(event_hash)
    response = Faraday.get(
      "#{@connection.chatwoot_endpoint}/api/v1/accounts/#{@connection.chatwoot_account_id}/contacts/search/?q=#{event_hash['from'].split('@')[0]}",
      {},
      { 'Content-Type': "application/json", "api_access_token": "#{@connection.chatwoot_account_token}" }
    )
    return JSON.parse(response.body)['payload'][0]
  end

  def update_chatwoot_message(chat_woot_message, message_wpp)
    response = Faraday.put(
      "#{@connection.chatwoot_endpoint}/api/v1/accounts/#{@connection.chatwoot_account_id}/conversations/#{chat_woot_message['conversation']['id']}/messages/#{chat_woot_message['id']}",
      {
        "external_source_ids": { "id": message_wpp['response'].first['id']}
      }.to_json,
      { 'Content-Type': "application/json", "api_access_token": "#{@connection.chatwoot_account_token}" }
    )
    return response.body
  end

  def receive_message?(event)
    event['event'] == 'onmessage' && event['fromMe'] == false
  end
end