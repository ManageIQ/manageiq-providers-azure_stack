FactoryBot.define do
  factory :ems_azure_stack,
          :aliases => ["manageiq/providers/azure_stack/cloud_manager"],
          :class   => "ManageIQ::Providers::AzureStack::CloudManager",
          :parent  => :ems_cloud

  factory :ems_azure_stack_with_authentication,
          :parent => :ems_azure_stack do
    azure_tenant_id { "ABCDEFGHIJABCDEFGHIJ0123456789AB" }
    subscription { "0123456789ABCDEFGHIJABCDEFGHIJKL" }
    after :create do |x|
      x.authentications << FactoryBot.create(:authentication)
    end
  end

  factory :ems_azure_stack_with_vcr_authentication, :parent => :ems_azure_stack do
    zone do
      _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
      zone
    end

    after(:build) do |ems|
      ems.provider_region = 'westus'
      ems.hostname = Rails.application.secrets.azure_stack.try(:[], 'host') || 'AZURE_STACK_HOST'
      ems.update(:azure_tenant_id => Rails.application.secrets.azure_stack.try(:[], 'tenant') || 'AZURE_STACK_TENANT')
      ems.update(:subscription    => Rails.application.secrets.azure_stack.try(:[], 'subscription') || 'AZURE_STACK_SUBSCRIPTION')
    end

    after(:create) do |ems|
      ems.authentications << FactoryBot.create(
        :authentication,
        :userid   => Rails.application.secrets.azure_stack.try(:[], 'userid') || 'AZURE_STACK_USERID',
        :password => Rails.application.secrets.azure_stack.try(:[], 'password') || 'AZURE_STACK_PASSWORD'
      )
    end
  end
end
