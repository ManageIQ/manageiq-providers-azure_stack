class ManageIQ::Providers::AzureStack::NetworkManager::RefreshWorker < ::MiqEmsRefreshWorker
  def self.settings_name
    :ems_refresh_worker_azure_stack_network
  end
end
