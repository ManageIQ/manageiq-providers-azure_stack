class ManageIQ::Providers::AzureStack::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :AvailabilityZone
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Flavor
  require_nested :MetricsCapture
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :ResourceGroup
  require_nested :Vm
  require_nested :OrchestrationStack
  require_nested :OrchestrationTemplate
  require_nested :OrchestrationServiceOptionConverter

  include ManageIQ::Providers::AzureStack::ManagerMixin

  alias_attribute :azure_tenant_id, :uid_ems

  has_many :resource_groups, :foreign_key => :ems_id, :dependent => :destroy, :inverse_of => false

  before_create :ensure_managers

  supports :create
  supports :metrics

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::AzureStack::NetworkManager') unless network_manager
  end

  def ensure_managers_zone_and_provider_region
    network_manager.zone_id = zone_id if network_manager
    # provider_region is passed over via delegation so no need to copy-paste
  end

  def self.my_settings
    Settings.ems.ems_azure_stack
  end

  def self.ems_type
    @ems_type ||= "azure_stack".freeze
  end

  def self.description
    @description ||= "Azure Stack".freeze
  end

  def self.api_allowed_attributes
    %w[azure_tenant_id].freeze
  end
end
