class ManageIQ::Providers::AzureStack::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager
  require_nested :TargetCollection

  include ManageIQ::Providers::AzureStack::EmsRefMixin

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

  def raw_power_state(instance_view)
    instance_view&.statuses&.detect { |s| s.code.start_with?('PowerState/') }&.code
  end
end
