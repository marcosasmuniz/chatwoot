class SuperAdmin::WppConnectsController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  def create
    ActiveRecord::Base.transaction do
      if params[:wpp_connect][:wppconnect_token].blank?
        request_token = HTTParty.post(
          "#{params[:wpp_connect][:wppconnect_endpoint]}/api/#{params[:wpp_connect][:wppconnect_session]}/#{params[:wpp_connect][:wppconnect_secret]}/generate-token",
          headers: { 'Content-Type' => 'application/json' }
        )
        puts(request_token.parsed_response)
        params[:wpp_connect][:wppconnect_token] = request_token.parsed_response['token']
      end

      account = Account.first
      channel = account.api_channels.create()
      inbox = account.inboxes.build({
        name: "#{params[:wpp_connect][:name]}",
        channel: channel
      })
      inbox.save!
      params[:wpp_connect][:channel_api_id] = channel.id
      super()
    end
  end

  def show
    account = Account.first
    if params.key?(:pair_qr)
      @retries_count = params[:retries_count].to_i
      wpp_connect = WppConnect.find(params[:id])
      if @retries_count > 20
        flash[:notice] = 'Error to connect'
        return super_admin_wpp_connect_path(wpp_connect.id)
      end

      request_status = HTTParty.get(
        "#{wpp_connect.wppconnect_endpoint}/api/#{wpp_connect.wppconnect_session}/status-session",
        headers: { 'Authorization' => "Bearer #{wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' }
      )
      if request_status.parsed_response['status'] == 'CLOSED'
        request_start = HTTParty.post(
          "#{wpp_connect.wppconnect_endpoint}/api/#{wpp_connect.wppconnect_session}/start-session",
          headers: { 'Authorization' => "Bearer #{wpp_connect.wppconnect_token}", 'Content-Type' => 'application/json' },
          body: {'webhook': "#{ENV['FRONTEND_URL']}/api/v1/integrations/wpp_connects/#{wpp_connect.id}/webhook", 'waitQrCode': true}.to_json
        )
        sleep(3)
        @retries_count += 1 
        return redirect_to super_admin_wpp_connect_path(wpp_connect.id, pair_qr: true, retries_count: @retries_count)
      elsif request_status.parsed_response['status'] == 'QRCODE'
        @qr_code = request_status.parsed_response['qrcode']
        @retries_count += 1
      elsif request_status.parsed_response['status'] == 'CONNECTED'
        flash[:notice] = 'Connected!'
        return redirect_to super_admin_wpp_connect_path(wpp_connect.id)
      end
    end
    super()
  end


  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  # def resource_params
  #   params.require(resource_class.model_name.param_key).
  #     permit(dashboard.permitted_attributes).
  #     transform_values { |value| value == "" ? nil : value }
  # end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information
end
