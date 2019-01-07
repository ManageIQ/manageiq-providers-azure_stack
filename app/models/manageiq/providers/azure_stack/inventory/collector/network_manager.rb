class ManageIQ::Providers::AzureStack::Inventory::Collector::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  def security_groups
    azure_network.network_security_groups.list_all
  end
end
