describe ManageIQ::Providers::AzureStack::CloudManager::Refresher do
  supported_api_versions do |api_version|
    before do
      stub_settings_merge(:ems_refresh => { :azure_stack => refresh_settings }) if refresh_settings
    end

    let(:resource_group)  { ResourceGroup.find_by(:name => 'demo-resource-group') }
    let(:security_group)  { SecurityGroup.find_by(:name => 'demoSecurityGroup') }
    let(:ems_ref_prefix)  { %r{^/subscriptions/[^/]+/resourcegroups/[^/]+} }
    let(:saving_strategy) { :recursive }
    let(:saver_strategy)  { :default }
    let(:use_ar)          { true }
    let(:refresh_settings) do
      {
        :inventory_object_refresh         => true,
        :inventory_object_saving_strategy => saving_strategy,
        :inventory_collections            => {
          :saver_strategy => saver_strategy,
          :use_ar_object  => use_ar
        }
      }
    end
    let!(:ems) do
      ems = FactoryBot.create(:ems_azure_stack_with_vcr_authentication, :skip_validate, :api_version => api_version)
      allow(ems).to receive(:hostname_format_valid?).and_return(true) # or else "AZURE_STACK_HOST" gets rejected
      ems
    end

    context 'with default settings' do
      let(:refresh_settings) { nil }
      it 'full refresh' do
        full_refresh_twice { assert_inventory }
      end
    end
  end

  def full_refresh_twice
    2.times do # Run twice to verify that a second run with existing data does not change anything
      ems.reload
      ems.network_manager.reload
      vcr_with_auth("#{described_class.name.underscore}/#{api_version}") { EmsRefresh.refresh(ems) }
      vcr_with_auth("#{described_class.name.underscore}/#{api_version}-network") { EmsRefresh.refresh(ems.network_manager) }
      ems.reload
      ems.network_manager.reload
      yield
    end
  end

  def assert_inventory
    assert_table_counts
    assert_resource_group
    assert_security_group
  end

  def assert_table_counts
    expect(ExtManagementSystem.count).to eq(1 + 1) # cloud + network manager
    expect(ResourceGroup.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
  end

  def assert_resource_group
    expect(resource_group).not_to be_nil
    expect(ems_ref_suffix(resource_group.ems_ref)).to eq('') # prefix is actually resource group ems_ref
  end

  def assert_security_group
    expect(security_group).not_to be_nil
    expect(ems_ref_suffix(security_group.ems_ref)).to match(%r{^/providers/microsoft.network/networksecuritygroups/[^/]+$})
  end

  def ems_ref_suffix(ems_ref)
    expect(ems_ref).to match(ems_ref_prefix) # fail if prefix not there, don't go continue silently
    ems_ref.sub(ems_ref_prefix, '')
  end
end
