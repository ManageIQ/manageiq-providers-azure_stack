#
# This inventory test comes with Azure deployment JSON which makes it reproducible on any Azure Stack.
# VCR cassettes were recorded against a fresh subscription with nothing but that JSON deployed.
# Please make sure tests stay in sync with the JSON - don't ever manually update VCR cassettes.
# Instead, modify the JSON and deploy it and then just re-record the cassettes.
#
# The JSON deployment is here:
# ../vcr_fixtures/full-refresh-deployment.json
#

describe ManageIQ::Providers::AzureStack::CloudManager::Refresher do
  supported_api_versions do |api_version|
    before do
      stub_settings_merge(:ems_refresh => { :azure_stack => refresh_settings }) if refresh_settings
    end

    let(:resource_group)  { ResourceGroup.find_by(:name => 'demo-resource-group') }
    let(:zone)            { AvailabilityZone.find_by(:ems_ref => 'default') }
    let(:vm)              { Vm.find_by(:name => 'demoVm') }
    let(:stack)           { OrchestrationStack.find_by(:name => 'Microsoft.Template') }
    let(:security_group)  { SecurityGroup.find_by(:name => 'demoSecurityGroup') }
    let(:flavor)          { Flavor.find_by(:ems_ref => 'standard_a1') }

    let(:network)         { CloudNetwork.find_by(:name => 'demoNetwork') }
    let(:subnet)          { CloudSubnet.find_by(:name => 'demoSubnet') }
    let(:network_port)    { NetworkPort.find_by(:name => 'demoNic0') }

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
    assert_availability_zone
    assert_specific_flavor
    assert_specific_vm
    assert_specific_orchestration_stack
    assert_specific_network
    assert_specific_subnet
    assert_specific_network_port
    assert_security_group
  end

  def assert_table_counts
    expect(ExtManagementSystem.count).to eq(1 + 1) # cloud + network manager
    expect(ResourceGroup.count).to eq(1)
    expect(AvailabilityZone.count).to eq(1)
    expect(Vm.count).to eq(1)
    expect(Flavor.count).to eq(70)
    expect(CloudNetwork.count).to eq(1)
    expect(CloudSubnet.count).to eq(1)
    expect(NetworkPort.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
    expect(OrchestrationStack.count).to eq(1)
  end

  def assert_resource_group
    expect(resource_group).not_to be_nil
    expect(ems_ref_suffix(resource_group.ems_ref)).to eq('') # prefix is actually resource group ems_ref
  end

  def assert_availability_zone
    expect(zone).not_to be_nil
    expect(zone.name).to eq(ems.name)
  end

  def assert_specific_flavor
    expect(flavor).not_to be_nil
    expect(flavor).to have_attributes(
      :ems_ref        => 'standard_a1',
      :name           => 'Standard_A1',
      :cpus           => 1,
      :cpu_cores      => 1,
      :memory         => 1.75.gigabytes.round,
      :root_disk_size => 1023.gigabytes.round,
      :swap_disk_size => 70.gigabytes.round,
      :enabled        => true
    )
  end

  def assert_specific_vm
    expect(vm).not_to be_nil
    expect(ems_ref_suffix(vm.ems_ref)).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+$})
    expect(ems_ref_suffix(vm.uid_ems)).to match(%r{^/providers/microsoft.compute/virtualmachines/[^/]+$})

    expect(vm).to have_attributes(
      :vendor              => 'azure_stack',
      :connection_state    => 'connected',
      :raw_power_state     => 'PowerState/running',
      :power_state         => 'on',
      :location            => 'westus',
      :availability_zone   => zone,
      :resource_group      => resource_group,
      :flavor              => flavor,
      :orchestration_stack => stack
    )

    expect(vm.operating_system).not_to be_nil
    expect(vm.operating_system.product_name).to eq('UbuntuServer 16.04 LTS')

    expect(vm.hardware).not_to be_nil
    expect(vm.hardware).to have_attributes(
      :cpu_sockets     => 1,
      :cpu_total_cores => 1,
      :memory_mb       => 1.75.gigabytes.round / 1.megabyte,
      :disk_capacity   => 70.gigabytes.round
    )
  end

  def assert_specific_orchestration_stack
    expect(stack).not_to be_nil
    expect(ems_ref_suffix(stack.ems_ref)).to match(%r{^/providers/microsoft.resources/deployments/[^/]+$})
    expect(stack).to have_attributes(
      :status         => 'Succeeded',
      :description    => stack.name,
      :resource_group => resource_group.name
    )
  end

  def assert_specific_network
    expect(network).not_to be_nil
    expect(ems_ref_suffix(network.ems_ref)).to match(%r{^/providers/microsoft.network/virtualnetworks/[^/]+$})
    expect(network.resource_group).to eq(resource_group)

    expect(network.cloud_subnets).not_to be_nil
    expect(network.cloud_subnets.size).to eq(1)
  end

  def assert_specific_subnet
    expect(subnet).not_to be_nil
    expect(ems_ref_suffix(subnet.ems_ref)).to match(%r{^/providers/microsoft.network/virtualnetworks/[^/]+/subnets/[^/]+$})

    expect(subnet.cloud_network).to eq(network)

    assert_security_groups_binding(subnet)
  end

  def assert_specific_network_port
    expect(network_port).not_to be_nil
    expect(ems_ref_suffix(network_port.ems_ref)).to match(%r{^/providers/microsoft.network/networkinterfaces/[^/]+$})
    expect(network_port).to have_attributes(
      :resource_group => resource_group,
      :mac_address    => '001DD8B70047',
      :device         => vm
    )

    assert_security_groups_binding(network_port)
  end

  def assert_security_groups_binding(entity)
    expect(entity.security_groups).not_to be_nil
    expect(entity.security_groups.size).to eq(1)
    expect(entity.security_groups.first).to eq(security_group)
  end

  def assert_security_group
    expect(security_group).not_to be_nil
    expect(ems_ref_suffix(security_group.ems_ref)).to match(%r{^/providers/microsoft.network/networksecuritygroups/[^/]+$})
    expect(security_group.resource_group).to eq(resource_group)
  end
end
