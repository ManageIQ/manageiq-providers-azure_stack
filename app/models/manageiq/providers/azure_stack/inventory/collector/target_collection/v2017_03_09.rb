# rubocop:disable Naming/ClassAndModuleCamelCase
class ManageIQ::Providers::AzureStack::Inventory::Collector::TargetCollection::V2017_03_09 < ManageIQ::Providers::AzureStack::Inventory::Collector::TargetCollection
  # ##################################
  # Target collection for CloudManager
  # ##################################
  def resources(group_ems_ref)
    group_name = resource_group_name(group_ems_ref)
    safe_call { azure_resources.resource_groups.list_resources(group_name) }
  end

  def vm(ems_ref)
    group_name, vm_name = resource_group_and_resource_name(ems_ref)
    safe_call do
      azure_compute.virtual_machines.get(group_name, vm_name, :expand => 'instanceView')
    end
  end
end
# rubocop:enable Naming/ClassAndModuleCamelCase
