describe ManageIQ::Providers::AzureStack::CloudManager::Vm do
  before { allow(subject).to receive(:with_provider_connection).with(:service => :Compute).and_yield(client) }

  let(:client)  { double('compute', :virtual_machines => actions) }
  let(:actions) { double('actions') }

  subject { FactoryBot.create(:vm_azure_stack, :raw_power_state => 'unknown') }

  describe '#raw_start' do
    it 'invokes' do
      expect(subject.power_state).to eq('unknown')
      expect(actions).to receive(:start).with('resource_group', subject.name)
      subject.raw_start
      subject.reload
      expect(subject.power_state).to eq('on')
    end
  end

  describe '#raw_stop' do
    it 'invokes' do
      expect(subject.power_state).to eq('unknown')
      expect(actions).to receive(:deallocate).with('resource_group', subject.name)
      subject.raw_stop
      subject.reload
      expect(subject.power_state).to eq('off')
    end
  end

  describe '#raw_suspend' do
    it 'invokes' do
      expect(subject.power_state).to eq('unknown')
      expect(actions).to receive(:stop).with('resource_group', subject.name)
      subject.raw_suspend
      subject.reload
      expect(subject.power_state).to eq('suspended')
    end
  end

  describe '#raw_pause' do
    it 'invokes' do
      expect(subject.power_state).to eq('unknown')
      expect(actions).to receive(:stop).with('resource_group', subject.name)
      subject.raw_pause
      subject.reload
      expect(subject.power_state).to eq('suspended')
    end
  end
end
