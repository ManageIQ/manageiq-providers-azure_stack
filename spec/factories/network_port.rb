FactoryBot.define do
  factory :network_port_azure_stack,
          :parent => :network_port,
          :class  => 'ManageIQ::Providers::AzureStack::NetworkManager::NetworkPort'
end
