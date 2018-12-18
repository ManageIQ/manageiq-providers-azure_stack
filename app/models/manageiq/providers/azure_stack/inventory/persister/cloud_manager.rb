class ManageIQ::Providers::AzureStack::Inventory::Persister::CloudManager < ManageIQ::Providers::AzureStack::Inventory::Persister
  include ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::CloudCollections

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
  end
end
