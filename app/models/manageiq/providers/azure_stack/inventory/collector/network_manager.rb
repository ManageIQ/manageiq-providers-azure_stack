class ManageIQ::Providers::AzureStack::Inventory::Collector::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  def networks
    azure_network.virtual_networks.list_all
  end

  def network_ports
    azure_network.network_interfaces.list_all
  end

  def security_groups
    azure_network.network_security_groups.list_all
  end
end
