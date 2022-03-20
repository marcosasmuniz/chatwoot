FactoryBot.define do
  factory :wpp_connect do
    name { 'Wpp Connect' }
    status { 'active' }
    wppconnect_session { 'text' }
    wppconnect_token { 'text' }
    wppconnect_endpoint { 'http://wppconnect-server' }
    channel_api { create(:channel_api) }
    wppconnect_secret { 'secret' }
  end
end
