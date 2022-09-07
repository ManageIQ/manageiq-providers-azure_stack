class ManageIQ::Providers::AzureStack::CloudManager::EventCatcher::Stream
  class ProviderUnreachable < ManageIQ::Providers::BaseManager::EventCatcher::Runner::TemporaryFailure
  end

  def initialize(ems, options = {})
    @ems = ems
    @stop_polling = false
    @since = options[:since]
  end

  def start
    @stop_polling = false
  end

  def stop
    @stop_polling = true
  end

  def poll
    @ems.with_provider_connection(:service => :Monitor) do |connection|
      catch(:stop_polling) do
        begin
          loop do
            throw :stop_polling if @stop_polling

            # Grab events for the last minute if this is the first poll
            @since ||= initial_time

            filter = "eventTimestamp ge #{@since.iso8601(3)}"
            events = connection.activity_logs.list({:filter => filter}).sort_by(&:event_timestamp)
            yield events

            @since = update_time(events) unless events.empty?
          end
        rescue => exception
          raise ProviderUnreachable, exception.message
        end
      end
    end
  end

  def initial_time
    Time.now.utc - 1.minute
  end

  def update_time(events)
    # HACK: the Azure Insights API does not support the 'gt' (greater than relational operator)
    # therefore we have to poll from 1 millisecond past the timestamp of the last event to avoid
    # gathering the same event more than once.
    events.last.event_timestamp.utc + 0.001.seconds
  end
end
