class ManageIQ::Providers::AzureStack::CloudManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    event_monitor_handle.stop
  end

  def monitor_events
    event_monitor_handle.start
    event_monitor_running
    event_monitor_handle.poll do |events|
      @queue.enq(events)
      sleep_poll_normal
    end
  ensure
    stop_event_monitor
  end

  def queue_event(event)
    event_hash = ManageIQ::Providers::AzureStack::CloudManager::EventParser.event_to_hash(event, @cfg[:ems_id])
    msg = "#{log_prefix} Caught AzureStack event [#{event_hash[:event_type]}] for [#{event_hash.dig(:full_data, :resource_id)}]"
    _log.info(msg)
    $azure_stack_log.debug("#{msg}: #{event_hash}")
    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end

  def event_monitor_handle
    @event_monitor_handle ||= begin
      self.class.module_parent::Stream.new(@ems)
    end
  end
end
