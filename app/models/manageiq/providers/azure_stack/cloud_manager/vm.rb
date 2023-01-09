class ManageIQ::Providers::AzureStack::CloudManager::Vm < ManageIQ::Providers::CloudManager::Vm
  include ManageIQ::Providers::AzureStack::EmsRefMixin

  supports :capture

  POWER_STATES = {
    'PowerState/running'      => 'on',
    'PowerState/starting'     => 'powering_up',
    'PowerState/stopped'      => 'suspended',
    'PowerState/stopping'     => 'suspending',
    'PowerState/deallocated'  => 'off',
    'PowerState/deallocating' => 'powering_down',
    'PowerState/unknown'      => 'unknown'
  }.freeze

  def raw_start
    with_provider_connection(:service => :Compute) do |client|
      client.virtual_machines.start(resource_group_name(ems_ref), name)
    end
    update!(:raw_power_state => 'PowerState/running')
  end

  def raw_stop
    with_provider_connection(:service => :Compute) do |client|
      client.virtual_machines.deallocate(resource_group_name(ems_ref), name)
    end
    update!(:raw_power_state => 'PowerState/deallocated')
  end

  def raw_suspend
    with_provider_connection(:service => :Compute) do |client|
      client.virtual_machines.stop(resource_group_name(ems_ref), name)
    end
    update!(:raw_power_state => 'PowerState/stopped')
  end
  alias raw_pause raw_suspend

  def self.calculate_power_state(raw_power_state)
    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/states-lifecycle
    POWER_STATES[raw_power_state.to_s] || 'unknown'
  end
end
