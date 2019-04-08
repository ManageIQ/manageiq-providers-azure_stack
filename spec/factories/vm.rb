FactoryBot.define do
  factory :vm_azure_stack, :class => 'ManageIQ::Providers::AzureStack::CloudManager::Vm', :parent => :vm_cloud do
    sequence(:name) { |n| "VM#{n}" }
    sequence(:ems_ref) do |n|
      "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/VM#{n}"
    end
    raw_power_state { 'PowerState/running' }
  end
end
