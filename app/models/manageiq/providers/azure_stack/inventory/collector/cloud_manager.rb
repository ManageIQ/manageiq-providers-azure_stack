class ManageIQ::Providers::AzureStack::Inventory::Collector::CloudManager < ManageIQ::Providers::AzureStack::Inventory::Collector
  def resource_groups
    azure_resources.resource_groups.list
  end
end
