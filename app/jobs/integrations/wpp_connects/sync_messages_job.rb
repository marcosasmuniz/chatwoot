class Integrations::WppConnects::SyncMessagesJob < ApplicationJob
  queue_as :low

  def perform(wpp_connect_id)
    return if have_others_job?
    wpp_connect = WppConnect.find(wpp_connect_id)
    perform_sync(wpp_connect)
    perform_sync(wpp_connect)
    return true
  end

  private
  
  def perform_sync(wpp_connect)
    WppConnects::SyncService.new(wpp_connect.reload).call()
  end

  def have_others_job?
    queue_size = 0
    running_size = 0

    queue = Sidekiq::Queue.new('low')
    queue_size = queue.size

    queue.each do | job |
      queue_size += 1 if job.queue == 'low' && job.args.first['job_class'] == 'Integrations::WppConnects::SyncMessagesJob'
    end

    workers = Sidekiq::Workers.new
    workers.each do |_process_id, _thread_id, work|
      running_size += 1 if work['queue'] == 'low' &&  work['payload']['wrapped'] == 'Integrations::WppConnects::SyncMessagesJob'
    end

    if ( (queue_size +  running_size) != 0 )
      return true
    else
      return false
    end
  end
end
