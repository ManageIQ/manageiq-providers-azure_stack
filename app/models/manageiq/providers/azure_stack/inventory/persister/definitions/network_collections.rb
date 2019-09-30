module ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    %i[cloud_networks
       cloud_subnets
       network_ports
       security_groups].each do |name|
      add_collection(network, name)
    end

    add_related_cloud_collections
  end

  def add_related_cloud_collections
    %i[resource_groups
       vms].each do |name|
      add_collection(cloud, name) do |builder|
        builder.add_properties(
          :parent   => manager.parent_manager,
          :strategy => :local_db_find_references
        )
      end
    end
  end
end
