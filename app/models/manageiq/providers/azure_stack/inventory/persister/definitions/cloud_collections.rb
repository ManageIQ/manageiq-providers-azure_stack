module ManageIQ::Providers::AzureStack::Inventory::Persister::Definitions::CloudCollections
  extend ActiveSupport::Concern

  def initialize_cloud_inventory_collections
    %i[
      availability_zones
      hardwares
      operating_systems
      flavors
      miq_templates
      vms
      orchestration_stacks
      resource_groups
    ].each do |name|
      add_collection(cloud, name)
    end
  end
end
