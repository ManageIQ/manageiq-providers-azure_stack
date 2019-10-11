describe ManageIQ::Providers::AzureStack::CloudManager::EventParser do
  describe '#event_to_hash' do
    let(:ems_id)        { 123 }
    let(:event_hash)    { described_class.event_to_hash(event, ems_id) }
    let(:full_data)     { event_hash[:full_data] }
    let(:resource_type) { 'Microsoft.Compute/virtualMachines' }
    let(:event) do
      double(
        'event',
        :authorization          => double('auth', :action => 'auth_action', :scope => 'auth_scope'),
        :caller                 => 'caller',
        :category               => double(:value => 'Administrative'),
        :claims                 => { :c => 'c' },
        :correlation_id         => 'correlation',
        :description            => 'description',
        :event_data_id          => 'event_data',
        :event_name             => double(:value => 'event_name'),
        :event_timestamp        => Time.parse('2019-01-07T20:00:00Z').utc,
        :id                     => '/Event/Id',
        :level                  => 'level',
        :operation_id           => 'operation_id',
        :operation_name         => double(:value => "#{resource_type}/restart/action"),
        :properties             => { :p => 'p' },
        :resource_group_name    => 'resource_group',
        :resource_id            => '/myResource/myId',
        :resource_provider_name => double(:value => 'resource_provider'),
        :resource_type          => double(:value => resource_type),
        :status                 => double(:value => 'Started'),
        :sub_status             => double(:value => 'SubStatus'),
        :submission_timestamp   => Time.parse('2019-01-07T22:00:00Z').utc,
        :subscription_id        => 'subscription',
        :tenant_id              => 'tenant'
      )
    end

    context 'vm event' do
      it 'base_data' do
        expect(event_hash).to include(
          :event_type => 'Administrative_Microsoft.Compute_virtualMachines_restart_Started',
          :source     => 'AZURESTACK',
          :ems_ref    => '/event/id',
          :timestamp  => '2019-01-07T20:00:00.000000Z',
          :vm_ems_ref => '/myresource/myid',
          :message    => '[/myResource/myId] - description',
          :ems_id     => 123
        )
      end

      it 'full_data' do
        expect(full_data).to include(
          :authorization_action   => 'auth_action',
          :authorization_scope    => 'auth_scope',
          :caller                 => 'caller',
          :category               => 'Administrative',
          :claims                 => { :c => 'c' },
          :correlation_id         => 'correlation',
          :description            => 'description',
          :event_data_id          => 'event_data',
          :event_name             => 'event_name',
          :event_timestamp        => '2019-01-07T20:00:00.000000Z',
          :id                     => '/Event/Id',
          :level                  => 'level',
          :operation_id           => 'operation_id',
          :operation_name         => 'Microsoft.Compute/virtualMachines/restart/action',
          :properties             => { :p => 'p' },
          :resource_group_name    => 'resource_group',
          :resource_id            => '/myResource/myId',
          :resource_provider_name => 'resource_provider',
          :resource_type          => 'Microsoft.Compute/virtualMachines',
          :status                 => 'Started',
          :sub_status             => 'SubStatus',
          :submission_timestamp   => '2019-01-07T22:00:00.000000Z',
          :subscription_id        => 'subscription',
          :tenant_id              => 'tenant'
        )
      end
    end

    context 'non vm event' do
      let(:resource_type) { 'Microsoft.Network/virtualNetworks' }

      it 'base_data' do
        expect(event_hash).to include(
          :event_type => 'Administrative_Microsoft.Network_virtualNetworks_restart_Started',
          :source     => 'AZURESTACK',
          :ems_ref    => '/event/id',
          :timestamp  => '2019-01-07T20:00:00.000000Z',
          :vm_ems_ref => nil,
          :message    => '[/myResource/myId] - description',
          :ems_id     => 123
        )
      end
    end
  end
end
