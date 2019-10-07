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
    ].each do |name|
      add_collection(cloud, name)
    end

    add_resource_groups
  end

  def add_resource_groups
    add_collection(cloud, :resource_groups, {}, {:auto_inventory_attributes => false}) do |builder|
      builder.add_properties(:model_class => ::ManageIQ::Providers::AzureStack::ResourceGroup)
      builder.add_default_values(:ems_id => manager.id)
    end
  end
end
