FactoryBot.define do
  factory :cloud_network_azure_stack,
          :parent => :cloud_network,
          :class  => 'ManageIQ::Providers::AzureStack::NetworkManager::CloudNetwork'
end
