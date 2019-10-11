describe ManageIQ::Providers::AzureStack::CloudManager::EventCatcher::Stream do
  let(:userid)        { Rails.application.secrets.azure_stack.try(:[], :userid) || 'AZURE_STACK_USERID' }
  let(:subscription)  { Rails.application.secrets.azure_stack.try(:[], :subscription) || 'AZURE_STACK_SUBSCRIPTION' }
  let(:capture_since) { Time.parse('2019-01-07T20:00:00Z').utc }

  let!(:ems) do
    ems = FactoryBot.create(:ems_azure_stack_with_vcr_authentication, :skip_validate, :api_version => api_version)
    allow(ems).to receive(:hostname_format_valid?).and_return(true) # or else "AZURE_STACK_HOST" gets rejected
    ems
  end

  subject { described_class.new(ems, :since => capture_since) }

  supported_api_versions do |api_version|
    describe '#poll' do
      it 'Administrative_Microsoft.Compute_virtualMachines_restart' do
        # Simulate event capture
        captured_events = []
        vcr_with_auth("#{described_class.name.underscore}/#{api_version}/poll-vm_restarted") do
          subject.poll do |events|
            captured_events = events
            subject.stop
          end
        end
        expect(captured_events.size).to be > 0

        raw_event = captured_events.detect do |evt|
          evt.operation_name.value == 'Microsoft.Compute/virtualMachines/restart/action' &&
            evt.status.value == 'Started'
        end
        expect(raw_event).not_to be_nil

        parsed_event = ManageIQ::Providers::AzureStack::CloudManager::EventParser.event_to_hash(raw_event, ems.id)
        assert_specific_event(parsed_event)
      end
    end
  end

  def assert_specific_event(event)
    expect(event).to include(
      :event_type => 'Administrative_Microsoft.Compute_virtualMachines_restart_Started',
      :source     => 'AZURESTACK',
      :timestamp  => '2019-01-08T15:27:39.396015Z',
      :ems_id     => ems.id
    )
    expect(ems_ref_suffix(event[:ems_ref])).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+/events/[^/]+/ticks/[^/]+$})
    expect(ems_ref_suffix(event[:vm_ems_ref])).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+$})
    expect(event[:message]).to match(%r{^\[.+\] - .*$})

    assert_specific_full_data(event[:full_data])
  end

  def assert_specific_full_data(full_data)
    expect(full_data).not_to be_nil
    expect(full_data).to include(
      :authorization_action   => 'Microsoft.Compute/virtualMachines/restart/action',
      :caller                 => CGI.escape(userid),
      :category               => 'Administrative',
      :description            => '',
      :event_name             => 'BeginRequest',
      :level                  => 'Informational',
      :operation_name         => 'Microsoft.Compute/virtualMachines/restart/action',
      :resource_provider_name => 'Microsoft.Compute',
      :resource_type          => 'Microsoft.Compute/virtualMachines',
      :status                 => 'Started',
      :sub_status             => '',
      :subscription_id        => subscription
    )
    expect(ems_ref_suffix(full_data[:authorization_scope].downcase)).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+$})
    expect(ems_ref_suffix(full_data[:id].downcase)).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+/events/[^/]+/ticks/[^/]+$})
    expect(ems_ref_suffix(full_data[:resource_id].downcase)).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+$})

    assert_not_blank(full_data[:correlation_id])
    assert_not_blank(full_data[:event_data_id])
    assert_not_blank(full_data[:level])
    assert_not_blank(full_data[:operation_id])
    assert_not_blank(full_data[:resource_group_name])
    assert_not_blank(full_data[:tenant_id])

    assert_iso_date(full_data[:event_timestamp])
    assert_iso_date(full_data[:submission_timestamp])

    expect(full_data[:claims]).to be_a Hash
  end

  def assert_not_blank(value)
    expect(value).to match(/^.+$/)
  end

  def assert_iso_date(value)
    expect(value).to match(%r{\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\d\d\d\dZ})
  end
end
