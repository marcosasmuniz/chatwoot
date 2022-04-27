class Connections::Chatwoot::ProcessWebhookJob < ApplicationJob
  def perform(params)
    params_hash = JSON.parse(params)
    if (send_message?(params_hash))
      @connection = Connection.find(params_hash['connection_id'])
      response = Faraday.post(
        "#{@connection.wppconnect_endpoint}/api/#{@connection.wppconnect_session}/send-message",
        {
          "phone": "55#{params_hash['conversation']['meta']['sender']['phone_number'].gsub("+55", "")}",
          "message": "#{params_hash['content']}",
          "isGroup": false
        }.to_json,
        { 'Content-Type': "application/json", "Authorization": "Bearer #{@connection.wppconnect_token}" }
      )
      message_wpp = JSON.parse(response.body)
      return { ok: response.body }
    end
  end

  def update_chatwoot_message(chat_woot_message, message_wpp)
    response = Faraday.put(
      "#{@connection.chatwoot_endpoint}/api/v1/accounts/#{@connection.chatwoot_account_id}/conversations/#{chat_woot_message['conversation']['id']}/messages/#{chat_woot_message['id']}",
      {
        "source_id": "#{message_wpp['response'].first['id']}",
        "external_source_ids": message_wpp['response'].first
      }.to_json,
      { 'Content-Type': "application/json", "api_access_token": "#{@connection.chatwoot_account_token}" }
    )
    return response.body
  end

  def send_message?(event)
    event['event'] == 'message_created' && event['private'] == false && event['message_type'] == 'outgoing'
  end
end