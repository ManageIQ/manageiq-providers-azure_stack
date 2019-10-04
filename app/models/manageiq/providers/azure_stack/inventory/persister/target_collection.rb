class ManageIQ::Providers::AzureStack::Inventory::Persister::TargetCollection < ManageIQ::Providers::AzureStack::Inventory::Persister
  include ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::CloudCollections
  include ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
    add_network_collections
  end

  def targeted?
    true
  end

  def strategy
    :local_db_find_missing_references
  end
end
