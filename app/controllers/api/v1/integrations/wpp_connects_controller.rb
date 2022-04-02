class Api::V1::Integrations::WppConnectsController < ApplicationController
  def webhook
    Integrations::WppConnects::EventsJob.set(wait: 1.second).perform_later(params.to_json)
    render json: { ok: 'success' }, status: :ok
  end
end
