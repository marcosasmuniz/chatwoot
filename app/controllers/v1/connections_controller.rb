class V1::ConnectionsController < V1::ApplicationController
  def chatwoot_webhook
    Connections::Chatwoot::ProcessWebhookJob.perform_later(params.to_json)
    render json: {status: params['id']}
  end

  def wpp_connect_webhook
    Connections::WppConnect::ProcessWebhookJob.perform_later(params.to_json)
    render json: {status: 'ok'}
  end
end
