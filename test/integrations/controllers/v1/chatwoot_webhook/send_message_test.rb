require "test_helper"

class V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  test "should success" do
    post v1_connection_chatwoot_webhook_path(1), params: {"id": 8,"content": "Teste 1","created_at": "2022-02-19T17:26:43.062Z","message_type": "outgoing","content_type": "text","private": false,"content_attributes": {},"source_id": nil,"sender": {"id": 1,"name": "John","email": "john@acme.inc","type": "user"},"inbox": {"id": 2,"name": "Whatsapp 1"},"conversation": {"additional_attributes": {"mail_subject": ""},"can_reply": true,"channel": "Channel::Api","contact_inbox": {"id": 2,"contact_id": 2,"inbox_id": 2,"source_id": "90b1bdd5-04ba-4a23-833f-3ba155329273","created_at": "2022-02-19T17:26:43.006Z","updated_at": "2022-02-19T17:26:43.006Z","hmac_verified": false,"pubsub_token": "CFqZKFEXtbReQYR7gaB37pDS"},"id": 2,"inbox_id": 2,"messages": [{"id": 8,"content": "Teste 1","account_id": 1,"inbox_id": 2,"conversation_id": 2,"message_type": 1,"created_at": 1645291603,"updated_at": "2022-02-19T17:26:43.062Z","private": false,"status": "sent","source_id": nil,"content_type": "text","content_attributes": {},"sender_type": "User","sender_id": 1,"external_source_ids": {},"conversation": {"assignee_id": 1},"sender": {"id": 1,"name": "John","available_name": "John","avatar_url": "https://www.gravatar.com/avatar/0d722ac7bc3b3c92c030d0da9690d981?d=404","type": "user","availability_status": nil,"thumbnail": "https://www.gravatar.com/avatar/0d722ac7bc3b3c92c030d0da9690d981?d=404"}}],"meta": {"sender": {"additional_attributes": {"description": "","company_name": "","social_profiles": {"twitter": "","facebook": "","linkedin": ""}},"custom_attributes": {},"email": nil,"id": 2,"identifier": nil,"name": "Zimobi Teste","phone_number": "+554197763432","pubsub_token": nil,"thumbnail": "","type": "contact"},"assignee": {"id": 1,"name": "John","available_name": "John","avatar_url": "https://www.gravatar.com/avatar/0d722ac7bc3b3c92c030d0da9690d981?d=404","type": "user","availability_status": nil,"thumbnail": "https://www.gravatar.com/avatar/0d722ac7bc3b3c92c030d0da9690d981?d=404"},"hmac_verified": false},"status": "open","custom_attributes": {},"snoozed_until": nil,"unread_count": 0,"agent_last_seen_at": 0,"contact_last_seen_at": 0,"timestamp": 1645291603},"account": {"id": 1,"name": "Acme Inc"},"event": "message_created"}
    assert_response :success
    assert_enqueued_jobs 1
    assert_equal(
      Connections::Chatwoot::ProcessWebhookJob.perform_now(enqueued_jobs.first['arguments'][0]).key?(:ok),
      true
    )
  end

  test 'should failed wpp connection send' do
  end

  test 'should failed chatwoot update message' do
  end
end
