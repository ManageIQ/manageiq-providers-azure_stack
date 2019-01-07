class ManageIQ::Providers::AzureStack::NetworkManager::RefreshWorker < ::MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::AzureStack::NetworkManager
  end

  def self.settings_name
    :ems_refresh_worker_azure_stack_network
  end
end
