FactoryBot.define do
  factory :security_group_azure_stack,
          :parent => :security_group,
          :class  => 'ManageIQ::Providers::AzureStack::NetworkManager::SecurityGroup'
end
