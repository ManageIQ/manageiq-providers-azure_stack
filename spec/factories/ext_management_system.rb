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
      ems.hostname = VcrSecrets.azure_stack.host
      ems.update(:azure_tenant_id => VcrSecrets.azure_stack.tenant)
      ems.update(:subscription    => VcrSecrets.azure_stack.subscription)
    end

    after(:create) do |ems|
      ems.authentications << FactoryBot.create(
        :authentication,
        :userid   => VcrSecrets.azure_stack.userid,
        :password => VcrSecrets.azure_stack.password
      )
    end
  end
end
