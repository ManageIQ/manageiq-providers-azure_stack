describe ManageIQ::Providers::AzureStack::CloudManager::EventTargetParser do
  supported_api_versions do |api_version|
    before do
      _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
      @ems = FactoryBot.create(:ems_azure_stack_with_vcr_authentication, :skip_validate, :api_version => api_version, :zone => zone)
    end

    let(:resource_group)     { 'demo-resource-group' }
    let(:resource_group_ref) { "/subscriptions/test/resourceGroups/#{resource_group}".downcase }

    it "event triggers targeted refresh of resource group" do
      event_data = event_double("/subscriptions/test/resourcegroups/#{resource_group}/dummyResources/dummy")
      assert_event_triggers_targets(event_data, [[:resource_groups, {:ems_ref => resource_group_ref}]])
    end

    it "event from which we cannot infer resource group does nothing" do
      event_data = event_double("dummy")
      assert_event_triggers_targets(event_data, [])
    end
  end

  def event_double(id)
    require 'azure_mgmt_monitor'
    Azure::Monitor::Profiles::Latest::Mgmt::Models::EventData.new.tap do |event|
      event.resource_id = id
      event.event_timestamp = Time.now.utc
    end
  end

  def assert_event_triggers_targets(event_data, expected_targets)
    ems_event      = create_ems_event(event_data)
    parsed_targets = described_class.new(ems_event).parse

    expect(parsed_targets.size).to eq(expected_targets.count)
    expect(target_references(parsed_targets)).to(match_array(expected_targets))
  end

  def target_references(parsed_targets)
    parsed_targets.map { |x| [x.association, x.manager_ref] }.uniq
  end

  def create_ems_event(event_data)
    event_hash = ManageIQ::Providers::AzureStack::CloudManager::EventParser.event_to_hash(event_data, @ems.id)
    EmsEvent.add(@ems.id, event_hash)
  end
end
