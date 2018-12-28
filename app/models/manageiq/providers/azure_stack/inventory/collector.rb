class ManageIQ::Providers::AzureStack::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager

  def azure_resources
    @azure_resources ||= manager.connect
  end
end
