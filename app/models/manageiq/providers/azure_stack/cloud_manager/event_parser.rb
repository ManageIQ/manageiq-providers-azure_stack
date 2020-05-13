module ManageIQ::Providers::AzureStack::CloudManager::EventParser
  INSTANCE_TYPE = "microsoft.compute/virtualmachines".freeze

  def self.event_to_hash(event, ems_id)
    full_data = event_full_data(event)

    {
      :event_type => event_type(event),
      :source     => 'AZURESTACK',
      :ems_ref    => full_data[:id]&.downcase,
      :timestamp  => full_data[:event_timestamp],
      :vm_ems_ref => full_data[:resource_type]&.downcase == INSTANCE_TYPE ? full_data[:resource_id]&.downcase : nil,
      :full_data  => full_data,
      :message    => "[#{event&.resource_id}] - #{event&.description}",
      :ems_id     => ems_id
    }
  end

  def self.event_type(event)
    event_category = event&.category&.value       # 'Administrative'
    operation      = event&.operation_name&.value # 'Microsoft.Compute/virtualMachines/restart/action'
                       &.sub(%r{/action$}, '')    # 'Microsoft.Compute/virtualMachines/restart'
                       &.gsub('/', '_')           # 'Microsoft.Compute_virtualMachines_restart'
    status         = event&.status&.value         # 'Succeeded'

    "#{event_category || 'unknown_category'}_#{operation || 'unknown_operation'}_#{status || 'unknown_status'}"
  end

  def self.event_full_data(event)
    {
      :authorization_action   => event&.authorization&.action,
      :authorization_scope    => event&.authorization&.scope,
      :caller                 => event&.caller,
      :category               => event&.category&.value,
      :claims                 => event&.claims,
      :correlation_id         => event&.correlation_id,
      :description            => event&.description,
      :event_data_id          => event&.event_data_id,
      :event_name             => event&.event_name&.value,
      :event_timestamp        => event&.event_timestamp&.utc&.iso8601(6),
      :id                     => event&.id,
      :level                  => event&.level,
      :operation_id           => event&.operation_id,
      :operation_name         => event&.operation_name&.value,
      :properties             => event&.properties,
      :resource_group_name    => event&.resource_group_name,
      :resource_id            => event&.resource_id,
      :resource_provider_name => event&.resource_provider_name&.value,
      :resource_type          => event&.resource_type&.value,
      :status                 => event&.status&.value,
      :sub_status             => event&.sub_status&.value,
      :submission_timestamp   => event&.submission_timestamp&.utc&.iso8601(6),
      :subscription_id        => event&.subscription_id,
      :tenant_id              => event&.tenant_id
    }
  end
end
