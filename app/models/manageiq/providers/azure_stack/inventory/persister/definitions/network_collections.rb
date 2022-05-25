module ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    add_network_collections
    add_related_cloud_collections
  end

  def add_network_collections
    %i[cloud_networks
       cloud_subnets
       network_ports
       security_groups].each do |name|
      add_network_collection(name)
    end
  end

  def add_related_cloud_collections
    %i[resource_groups
       vms].each do |name|
      add_cloud_collection(name) do |builder|
        builder.add_properties(
          :strategy => :local_db_find_references
        )
      end
    end
  end
end
