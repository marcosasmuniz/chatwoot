require 'rails_helper'

RSpec.describe 'WppConnects::SyncService', type: :model do
  describe 'sync' do
    context 'should success' do
      let(:wpp_connect) do
        create(:wpp_connect, name: 'Teste 1',
                             status: 'active', wppconnect_session: 'phone1chatwoot', wppconnect_token: '$2b$10$el7thHgNihjWEqWyRrMe7.Jl3z9I.3uYyZv2L2yZPO70lUclk0f5i',
                             created_at: DateTime.parse('2022-03-08 23:41:51')
            )
      end
      let(:inbox) { wpp_connect.channel_api.inbox }

      it do
        stub_request(:get, /host-device/).to_return(headers: { content_type: 'application/json' }, body: File.new('spec/integrations/services/wpp_connects/stubs/should_success/host-device.json'))
        stub_request(:get, /all-chats/).to_return(headers: { content_type: 'application/json' }, body: File.new('spec/integrations/services/wpp_connects/stubs/should_success/all-chats.json'))
        stub_request(:get, /9999999999991/).to_return(headers: { content_type: 'application/json' }, body: File.new('spec/integrations/services/wpp_connects/stubs/should_success/contact1.json'))
        stub_request(:get, /9999999999992/).to_return(headers: { content_type: 'application/json' }, body: File.new('spec/integrations/services/wpp_connects/stubs/should_success/contact2.json'))
        expect(WppConnects::SyncService.new(wpp_connect).call).to eq(true)
        expect(WppConnects::SyncService.new(wpp_connect).call).to eq(true)
        expect(Contact.all.count).to eq(2)
        expect(Conversation.all.count).to eq(2)
        expect(Message.all.count).to eq(4)
      end
    end
  end
end
