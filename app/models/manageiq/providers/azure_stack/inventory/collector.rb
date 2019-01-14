class ManageIQ::Providers::AzureStack::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager

  def initialize(manager, refresh_target)
    super(manager, refresh_target)
    @token = nil
  end

  def azure_resources
    with_shared_token { |token| @azure_resources ||= manager.connect(:token => token) }
  end

  def azure_compute
    with_shared_token { |token| @azure_compute ||= manager.connect(:token => token, :service => :Compute) }
  end

  def azure_network
    with_shared_token { |token| @azure_network ||= manager.connect(:token => token, :service => :Network) }
  end

  def with_shared_token
    client = yield @token
    @token ||= client.credentials
    client
  end

  def resource_group_name(ems_ref)
    if (match = ems_ref.match(%r{/subscriptions/[^/]+/resourceGroups/(?<name>[^/]+)/.+}))
      match[:name].downcase
    end
  end

  def resource_group_id(ems_ref)
    if (match = ems_ref.match(%r{(?<id>/subscriptions/[^/]+/resourceGroups/[^/]+)/.+}))
      match[:id].downcase
    end
  end

  def raw_power_state(instance_view)
    instance_view&.statuses&.detect { |s| s.code.start_with?('PowerState/') }&.code
  end
end
