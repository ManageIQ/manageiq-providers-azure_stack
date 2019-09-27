# This class contains a reference implementation of collector for NetworkManager.
# The methods implemented here are completely aligned with the V2018_03_01 version profile.
class ManageIQ::Providers::AzureStack::Inventory::Collector::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  require_nested :V2018_03_01
  require_nested :V2017_03_09

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
