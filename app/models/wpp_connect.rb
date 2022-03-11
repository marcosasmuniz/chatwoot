# == Schema Information
#
# Table name: wpp_connects
#
#  id                  :bigint           not null, primary key
#  name                :string           default(""), not null
#  status              :string           default("active"), not null
#  status_sync         :jsonb            not null
#  wppconnect_endpoint :string           not null
#  wppconnect_session  :string           not null
#  wppconnect_token    :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  channel_api_id      :integer          not null
#
class WppConnect < ApplicationRecord
  belongs_to :channel_api, class_name: 'Channel::Api'

  after_create_commit :sync

  def sync
    Integrations::WppConnects::SyncMessagesJob.perform_later(self.id)
  end
end
