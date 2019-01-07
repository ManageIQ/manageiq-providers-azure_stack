class ManageIQ::Providers::AzureStack::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :CloudManager

  def azure_resources
    @azure_resources ||= manager.connect
  end

  def azure_network
    @azure_network ||= manager.connect(:service => :Network)
  end
end
