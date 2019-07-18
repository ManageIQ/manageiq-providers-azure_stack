FactoryBot.define do
  factory :orchestration_stack_azure_stack,
          :parent => :orchestration_stack,
          :class  => "ManageIQ::Providers::AzureStack::CloudManager::OrchestrationStack"
end
