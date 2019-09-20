class ManageIQ::Providers::AzureStack::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :CloudNetwork
  require_nested :CloudSubnet
  require_nested :NetworkPort
  require_nested :SecurityGroup

  delegate :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :authentications,
           :authentication_for_summary,
           :zone,
           :connect,
           :verify_credentials,
           :with_provider_connection,
           :address,
           :ip_address,
           :hostname,
           :default_endpoint,
           :endpoints,
           :azure_tenant_id,
           :provider_region,
           :to        => :parent_manager,
           :allow_nil => true

  def description
    provider_region
  end

  def self.ems_type
    @ems_type ||= "azure_stack_network".freeze
  end

  def self.description
    @description ||= "Azure Stack Network".freeze
  end

  def self.hostname_required?
    false
  end

  def self.display_name(number = 1)
    n_('Network Manager (Microsoft Azure Stack)', 'Network Managers (Microsoft Azure Stack)', number)
  end
end
