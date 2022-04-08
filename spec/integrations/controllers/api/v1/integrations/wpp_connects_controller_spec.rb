require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v1/integrations/wpp_connects/:wp_connects/webhook' do
    context 'on message' do
      context 'receive message' do
        let(:wpp_connect) { create(:wpp_connect, id: 25) }
        let(:event) { File.read('spec/integrations/controllers/api/v1/integrations/stubs/event.json') }
        let(:file_message_event) { File.read('spec/integrations/controllers/api/v1/integrations/stubs/file_message.json') }
        it 'create message' do
          assert_enqueued_with(job: Integrations::WppConnects::EventsJob) do
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            expect(Integrations::WppConnects::EventsJob.new.perform(event).content).to eq('hm')
          end
        end
  
        it 'update message' do
          assert_enqueued_with(job: Integrations::WppConnects::EventsJob) do
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            expect(Integrations::WppConnects::EventsJob.new.perform(event).content).to eq('hm')
            messages_count = Message.count
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            expect(Integrations::WppConnects::EventsJob.new.perform(event).content).to eq('hm')
            expect(Message.count).to eq(messages_count)
          end
        end

        it 'file message' do
          assert_enqueued_with(job: Integrations::WppConnects::EventsJob) do
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: file_message_event,
            as: :json
  
            expect(response.status).to eq(200)
            result = Integrations::WppConnects::EventsJob.new.perform(file_message_event)
            expect(result.content).to eq(nil)
            expect(result.attachments.count).to eq(1)
          end
        end
      end

      context 'send message from device' do
        let(:wpp_connect) { create(:wpp_connect, id: 25) }
        let(:event) { File.read('spec/integrations/controllers/api/v1/integrations/stubs/event_send_message.json') }
        let(:event_hash) { JSON.parse(event) }
        let(:message_db) { Message.find_by({'source_id': event_hash['id']['_serialized']}) }

        it 'create message' do
          assert_enqueued_with(job: Integrations::WppConnects::EventsJob) do
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            result = Integrations::WppConnects::EventsJob.new.perform(event)
            expect(result.content).to eq('teste4')
            expect(result.message_type).to eq('outgoing')
          end
        end
  
        it 'update message' do
          assert_enqueued_with(job: Integrations::WppConnects::EventsJob) do
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            expect(Integrations::WppConnects::EventsJob.new.perform(event).content).to eq('teste4')
            messages_count = Message.count
            conversations_count = Conversation.count
            post api_v1_integrations_wpp_connect_webhook_path(wpp_connect),
            params: event,
            as: :json
  
            expect(response.status).to eq(200)
            expect(Integrations::WppConnects::EventsJob.new.perform(event).content).to eq('teste4')
            expect(Message.count).to eq(messages_count)
            expect(Conversation.count).to eq(conversations_count)
            expect(message_db.message_type).to eq('outgoing')
          end
        end
      end
    end
  end
end
