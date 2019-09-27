# rubocop:disable Naming/ClassAndModuleCamelCase
class ManageIQ::Providers::AzureStack::Inventory::Collector::CloudManager::V2017_03_09 < ManageIQ::Providers::AzureStack::Inventory::Collector::CloudManager
  def vms
    $azure_stack_log.debug("Fetching VM ids, then fetching full data for each")
    azure_resources.resources.list(:filter => "resourceType eq 'Microsoft.Compute/virtualMachines'").map do |vm|
      azure_compute.virtual_machines.get(resource_group_name(vm.id), vm.name, :expand => 'instanceView')
    end
  end

  def orchestration_stacks
    resource_groups.flat_map do |group|
      azure_resources.deployments.list(group.name).map do |deployment|
        [
          group,                                                                   # resource group
          deployment,                                                              # deployment
          azure_resources.deployment_operations.list(group.name, deployment.name)  # operations of the deployment
        ]
      end
    end
  end
end
# rubocop:enable Naming/ClassAndModuleCamelCase
