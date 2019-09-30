# This class contains a reference implementation of collector for CloudManager.
# The methods implemented here are completely aligned with the V2018_03_01 version profile.
class ManageIQ::Providers::AzureStack::Inventory::Collector::CloudManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  require_nested :V2018_03_01
  require_nested :V2017_03_09

  def resource_groups
    @resource_groups ||= azure_resources.resource_groups.list
  end

  def flavors
    azure_compute.virtual_machine_sizes.list(manager.provider_region).value
  end

  def vms
    $azure_stack_log.debug("Fetching VMs, then fetching instance view for each")
    azure_compute.virtual_machines.list_all.each do |vm|
      vm.instance_view = azure_compute.virtual_machines.instance_view(resource_group_name(vm.id), vm.name)
    end
  end

  def orchestration_stacks
    resource_groups.flat_map do |group|
      azure_resources.deployments.list_by_resource_group(group.name).map do |deployment|
        [
          group,                                                                   # resource group
          deployment,                                                              # deployment
          azure_resources.deployment_operations.list(group.name, deployment.name)  # operations of the deployment
        ]
      end
    end
  end
end
