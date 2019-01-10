describe ManageIQ::Providers::AzureStack::CloudManager::EventCatcher::Runner do
  before do
    allow_any_instance_of(described_class).to receive_messages(:worker_initialization => nil, :after_initialize => nil)
    allow(subject).to receive(:worker_settings).and_return({})
    subject.instance_variable_set(:@ems, ems)
    subject.instance_variable_set(:@cfg, :ems_id => ems.id)
  end

  let(:ems)    { double('ems', :id => 123).as_null_object }
  let(:events) { %w[event1 event2] }

  it '.monitor_events' do
    subject.instance_variable_set(:@queue, Queue.new)
    expect(subject).to receive(:sleep_poll_normal)
    expect(subject).to receive(:event_monitor_running)
    expect(subject.event_monitor_handle).to receive(:poll).and_yield(events)

    subject.monitor_events

    expect(subject.instance_variable_get(:@queue).size).to eq(1)
  end

  describe '.queue_event' do
    let(:event) { double('event', :id => '/event/456').as_null_object }

    it 'pushes parsed event to the queue' do
      expect(EmsEvent).to receive(:add_queue) do |method, ems_id, event_hash|
        expect(method).to eq('add')
        expect(ems_id).to eq(123)
        expect(event_hash).to include(:source => 'AZURE_STACK', :ems_ref => '/event/456')
      end
      subject.queue_event(event)
    end
  end
end
