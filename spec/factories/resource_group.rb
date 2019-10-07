FactoryBot.define do
  factory :resource_group_azure_stack,
          :parent => :resource_group,
          :class  => 'ManageIQ::Providers::AzureStack::ResourceGroup'
end
