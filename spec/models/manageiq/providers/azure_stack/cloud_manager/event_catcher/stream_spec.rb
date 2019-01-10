describe ManageIQ::Providers::AzureStack::CloudManager::EventCatcher::Stream do
  let(:ems)  { double('ems', :id => '123').tap { |e| allow(e).to receive(:with_provider_connection).and_yield(conn) } }
  let(:conn) { double('conn').tap { |c| allow(c).to receive_message_chain(:activity_logs, :list).and_return(*batches) } }
  let(:t)    { Time.parse('2019-01-07T20:00:00Z').utc }

  subject { described_class.new(ems) }

  before { allow(Time).to receive(:now).and_return(t) }

  describe '.poll' do
    let(:evt1) { double('evt1', :id => 'id1', :event_timestamp => t + 0.seconds).as_null_object }
    let(:evt2) { double('evt2', :id => 'id2', :event_timestamp => t + 1.second).as_null_object }
    let(:evt3) { double('evt3', :id => 'id3', :event_timestamp => t + 2.seconds).as_null_object }
    let(:evt4) { double('evt4', :id => 'id4', :event_timestamp => t + 3.seconds).as_null_object }

    context 'one batch' do
      let(:batches)     { [event_batch] }
      let(:event_batch) { [evt4, evt2, evt3, evt1] }

      context 'unsorted event timestamps' do
        it 'get sorted' do
          expect(consume_events.map(&:id)).to eq(%w[id1 id2 id3 id4])
        end
      end

      context 'error' do
        it 'is handled' do
          expect { consume_events { |_| raise StandardError, 'BOOM' } }.to raise_error(described_class::ProviderUnreachable)
        end
      end
    end

    context 'two batches' do
      let(:event_batch1) { [evt2, evt1] }
      let(:event_batch2) { [evt3, evt4] }
      let(:batches)      { [event_batch1, event_batch2] }

      it 'each is sorted' do
        expect(consume_events.map(&:id)).to eq(%w[id1 id2 id3 id4])
      end

      it 'since gets updated after 1st and after 2nd batch' do
        consume_events do |batch_idx|
          case batch_idx
          when 0
            expect(subject.instance_variable_get(:@since)).to eq(t - 1.minute)
          when 1
            expect(subject.instance_variable_get(:@since)).to eq(evt2.event_timestamp + 0.001.seconds)
          end
        end
      end

      context 'second batch empty' do
        let(:event_batch2) { [] }

        it 'both batches succeed' do
          expect(consume_events.map(&:id)).to eq(%w[id1 id2])
        end
      end
    end

    def consume_events
      res = []
      n = batches.size
      subject.poll do |events|
        res.concat(events)
        yield batches.size - n if block_given?
        subject.stop if (n -= 1) && n <= 0 # exit loop as soon as batches are expected to be exhausted
      end
      res
    end
  end
end
