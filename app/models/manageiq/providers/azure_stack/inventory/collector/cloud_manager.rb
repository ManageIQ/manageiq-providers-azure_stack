class ManageIQ::Providers::AzureStack::Inventory::Collector::CloudManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  def resource_groups
    azure_resources.resource_groups.list
  end

  def flavors
    azure_compute.virtual_machine_sizes.list(manager.provider_region).value
  end

  def vms
    if azure_compute.respond_to?(:instance_view)
      $azure_stack_log.debug("Fetching VMs, then fetching instance view for each")
      azure_compute.virtual_machines.list_all.each do |vm|
        vm.instance_view = azure_compute.virtual_machines.instance_view(resource_group_name(vm.id), vm.name)
      end
    else
      $azure_stack_log.debug("Fetching VM ids, then fetching full data for each")
      azure_resources.resources.list(:filter => "resourceType eq 'Microsoft.Compute/virtualMachines'").map do |vm|
        azure_compute.virtual_machines.get(resource_group_name(vm.id), vm.name, :expand => 'instanceView')
      end
    end
  end
end
