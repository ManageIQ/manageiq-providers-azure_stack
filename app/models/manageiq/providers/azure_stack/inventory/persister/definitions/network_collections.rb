module ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    %i[cloud_networks
       cloud_subnets
       network_ports
       security_groups].each do |name|
      add_collection(network, name)
    end

    add_collection(cloud, :vms) do |builder|
      builder.add_properties(
        :parent   => manager.parent_manager,
        :strategy => :local_db_find_references
      )
    end
  end
end
