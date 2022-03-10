class Api::V1::Integrations::WppConnectsController < ApplicationController
  def webhook
    Integrations::WppConnects::SyncMessagesJob.perform_later(params[:wpp_connect_id])
    render json: { ok: 'success' }, status: :ok
  end
end
