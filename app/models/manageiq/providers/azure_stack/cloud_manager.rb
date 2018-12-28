class ManageIQ::Providers::AzureStack::CloudManager < ManageIQ::Providers::CloudManager
  require_nested :MetricsCapture
  require_nested :MetricsCollectorWorker
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :Vm

  include ManageIQ::Providers::AzureStack::ManagerMixin

  alias_attribute :azure_tenant_id, :uid_ems

  has_many :resource_groups, :foreign_key => :ems_id, :dependent => :destroy, :inverse_of => false

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
