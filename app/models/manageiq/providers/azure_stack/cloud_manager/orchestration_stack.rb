class ManageIQ::Providers::AzureStack::CloudManager::OrchestrationStack < ManageIQ::Providers::CloudManager::OrchestrationStack
  require_nested :Status

  def self.display_name(number = 1)
    n_('Orchestration Stack (Microsoft AzureStack)', 'Orchestration Stacks (Microsoft AzureStack)', number)
  end
end
