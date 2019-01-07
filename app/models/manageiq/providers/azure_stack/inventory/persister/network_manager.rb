class ManageIQ::Providers::AzureStack::Inventory::Persister::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Persister
  include ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections

  def initialize_inventory_collections
    initialize_network_inventory_collections
  end
end
