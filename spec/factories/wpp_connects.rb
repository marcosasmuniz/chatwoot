FactoryBot.define do
  factory :wpp_connect do
    name { 'Wpp Connect' }
    status { 'active' }
    wppconnect_session { 'text' }
    wppconnect_token { 'text' }
    wppconnect_endpoint { 'text'}
    channel_api { create(:channel_api) }
  end
end
