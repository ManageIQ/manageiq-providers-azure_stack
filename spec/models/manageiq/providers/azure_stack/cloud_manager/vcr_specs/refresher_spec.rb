describe ManageIQ::Providers::AzureStack::CloudManager::Refresher do
  supported_api_versions do |api_version|
    before do
      stub_settings_merge(:ems_refresh => { :azure_stack => refresh_settings }) if refresh_settings
    end

    let(:resource_group)  { ResourceGroup.find_by(:name => 'demo-resource-group') }
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
      vcr_with_auth("#{described_class.name.underscore}/#{api_version}") { EmsRefresh.refresh(ems) }
      ems.reload
      yield
    end
  end

  def assert_inventory
    assert_table_counts
    assert_resource_group
  end

  def assert_table_counts
    expect(ExtManagementSystem.count).to eq(1)
    expect(ResourceGroup.count).to eq(1)
  end

  def assert_resource_group
    expect(resource_group).not_to be_nil
    expect(resource_group.ems_ref).to match(%r{^/subscriptions/[^/]+/resourcegroups/[^/]+$})
  end
end
