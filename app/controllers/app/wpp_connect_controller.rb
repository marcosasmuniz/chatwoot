class App::WppConnectController < ApplicationController
  include AccessTokenAuthHelper
  before_action :authenticate_access_token!
  before_action :set_wpp_connect, only: [:show, :qr_code]

  def show
  end

  def new
    @wpp_connect = WppConnect.new
  end

  def create
    ActiveRecord::Base.transaction do
      @wpp_connect = WppConnect.new
      session = SecureRandom.urlsafe_base64(nil, false)
      request_token = HTTParty.post(
        "#{ENV['WPPCONNECT_ENDPOINT']}/api/#{session}/#{ENV['WPPCONNECT_SECRET']}/generate-token",
        headers: { 'Content-Type' => 'application/json' }
      )
      token = request_token.parsed_response['token']

      account = Current.user.accounts.find(params[:account_id])
      channel = account.api_channels.create()
      inbox = account.inboxes.build({
        name: "#{params[:wpp_connect][:name]}",
        channel: channel
      })
      inbox.save!
      @wpp_connect.name = params[:wpp_connect][:name]
      @wpp_connect.wppconnect_session = session
      @wpp_connect.wppconnect_token = token
      @wpp_connect.channel_api_id = channel.id
      @wpp_connect.wppconnect_endpoint = ENV['WPPCONNECT_ENDPOINT']
      @wpp_connect.save
    end

    redirect_to app_wpp_connect_qr_code_path(
      api_access_token: params[:api_access_token], wpp_connect_id: @wpp_connect.id, account_id: params[:account_id]
    )
  end

  def qr_code
    account = Account.first
    @retries_count = params[:retries_count].to_i
    if @retries_count > 20
      flash[:error] = 'Erro ao conectar'
      return redirect_to app_wpp_connect_show_path(api_access_token: params[:api_access_token], wpp_connect_id: @wpp_connect.id, account_id: params[:account_id])
    end
    frontend_url = Rails.env.production? ? ENV['FRONTEND_URL'] : 'http://rails:3000'

    request_status = HTTParty.get(
      "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/status-session",
      headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
    )
    if request_status.parsed_response['status'] == 'CLOSED'
      request_start = HTTParty.post(
        "#{@wpp_connect.wppconnect_endpoint}/api/#{@wpp_connect.wppconnect_session}/start-session",
        headers: { 'Authorization' => "Bearer #{@wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' },
        body: {'webhook': "#{frontend_url}/api/v1/integrations/wpp_connects/#{@wpp_connect.id}/webhook", 'waitQrCode': true}.to_json
      )
      sleep(3)
      @retries_count += 1 
    elsif request_status.parsed_response['status'] == 'QRCODE'
      @qr_code = request_status.parsed_response['qrcode']
      @retries_count += 1
    elsif request_status.parsed_response['status'] == 'CONNECTED'
      flash[:notice] = 'Connected!'
      @wpp_connect.update(status_connection: 'connected')
      @wpp_connect.sync()
      return redirect_to app_wpp_connect_show_path(
        api_access_token: params[:api_access_token], wpp_connect_id: @wpp_connect.id, account_id: params[:account_id]
      )
    end
  end

  def wpp_connect_params
    params.require(:wpp_connect).permit(:name)
  end

  def set_wpp_connect
    @wpp_connect = Current.user.accounts.find(params[:account_id]).wpp_connects.find(params[:wpp_connect_id])
  end
end
