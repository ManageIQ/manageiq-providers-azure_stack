module ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    add_collection(network, :security_groups)
  end
end
