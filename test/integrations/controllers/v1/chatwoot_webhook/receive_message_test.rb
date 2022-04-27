require "test_helper"

class V1::ConnectionsControllerTest < ActionDispatch::IntegrationTest

  valid_message = {
    "event" => "onmessage",
    "session" => "phone1chatwoot",
    "id" => "false_554197763432@c.us_3EB0F96F930950C32907",
    "body" => "teste 6",
    "type" => "chat",
    "t" => 1645656840,
    "notifyName" => "Rafael Fontana",
    "from" => "554197763432@c.us",
    "to" => "554196910256@c.us",
    "self" => "in",
    "ack" => 1,
    "isNewMsg" => true,
    "star" => false,
    "recvFresh" => true,
    "isFromTemplate" => false,
    "broadcast" => false,
    "mentionedJidList" => [],
    "isVcardOverMmsDocument" => false,
    "isForwarded" => false,
    "hasReaction" => false,
    "ephemeralOutOfSync" => false,
    "productHeaderImageRejected" => false,
    "lastPlaybackProgress" => 0,
    "isDynamicReplyButtonsMsg" => false,
    "isMdHistoryMsg" => false,
    "requiresDirectConnection" => false,
    "chatId" => "554197763432@c.us",
    "fromMe" => false,
    "sender" => {
      "id" => "554197763432@c.us",
      "name" => "Inquilinos Zimobi",
      "shortName" => "Inquilinos",
      "pushname" => "Rafael Fontana",
      "type" => "in",
      "isBusiness" => false,
      "isEnterprise" => false,
      "isContactSyncCompleted" => 0,
      "formattedName" => "Inquilinos Zimobi",
      "isMe" => false,
      "isMyContact" => true,
      "isPSA" => false,
      "isUser" => true,
      "isWAContact" => true,
      "profilePicThumbObj" => {
        "eurl" => "https://pps.whatsapp.net/v/t61.24694-24/267852083_4579054035497421_2473281010064620070_n.jpg?ccb=11-4&oh=4ae3c6a6a5709abfbdf2e9413a12adcf&oe=621C8780",
        "id" => "554197763432@c.us",
        "img" => "https://pps.whatsapp.net/v/t61.24694-24/267852083_4579054035497421_2473281010064620070_n.jpg?stp=dst-jpg_s96x96&ccb=11-4&oh=aa3a93370755445212debd53a216d566&oe=621C8780",
        "imgFull" => "https://pps.whatsapp.net/v/t61.24694-24/267852083_4579054035497421_2473281010064620070_n.jpg?ccb=11-4&oh=4ae3c6a6a5709abfbdf2e9413a12adcf&oe=621C8780",
        "raw" => nil,
        "tag" => "1643225166"
      },
      "msgs" => nil
    },
    "timestamp" => 1645656840,
    "content" => "teste 6",
    "isGroupMsg" => false,
    "isMedia" => false,
    "isNotification" => false,
    "isPSA" => false,
    "mediaData" => {}
  }

  test "should receive valid message" do
    post v1_connection_wpp_connect_webhook_path(1), params: valid_message
    assert_response :success
    assert_enqueued_jobs 1
    assert_equal(
      Connections::WppConnect::ProcessWebhookJob.perform_now(enqueued_jobs.first['arguments'][0]).key?(:ok),
      true
    )
  end

  test 'should failed wpp connection send' do
  end

  test 'should failed chatwoot update message' do
  end
end