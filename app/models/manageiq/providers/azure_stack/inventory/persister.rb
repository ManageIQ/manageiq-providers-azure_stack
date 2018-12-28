class ManageIQ::Providers::AzureStack::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :CloudManager
end
