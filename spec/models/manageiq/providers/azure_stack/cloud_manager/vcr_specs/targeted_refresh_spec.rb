describe ManageIQ::Providers::AzureStack::CloudManager::Refresher do
  let(:subscription) { VcrSecrets.azure_stack.subscription }

  REFRESH_SETTINGS = [
    {
      :allow_targeted_refresh   => true,
      :inventory_collections    => {
        :saver_strategy => :default
      }
    }
  ].freeze

  supported_api_versions do |api_version|
    let!(:ems) { FactoryBot.create(:ems_azure_stack_with_vcr_authentication, :skip_validate, :api_version => api_version) }

    describe "targeted refresh" do
      # names of test resources in the VCR cassettes
      let(:resource_group_name) { 'demo-resource-group' }
      let(:vm_name)             { 'demoVm' }
      let(:network_name)        { 'demoNetwork' }
      let(:port_name)           { 'demoNic0' }
      let(:security_group_name) { 'demoSecurityGroup' }

      REFRESH_SETTINGS.each do |refresh_settings|
        context "with settings #{refresh_settings}" do
          before(:each) do
            stub_settings_merge(
              :ems_refresh => {
                :azure_stack         => refresh_settings,
                :azure_stack_network => refresh_settings
              }
            )
          end

          let(:resource_group_ref) { "/subscriptions/#{subscription}/resourcegroups/#{resource_group_name}".downcase }
          # ensure that the flavor associated with the VM in our
          # test deployment is present in the DB
          let!(:flavor) do
            FactoryBot.create(:flavor,
                              :ems_id  => ems.id,
                              :ems_ref => 'standard_a1',
                              :memory  => 1.gigabyte)
          end

          describe "on empty database" do
            let(:resource_group) do
              FactoryBot.build(:resource_group_azure_stack,
                               :ems_id  => ems.id,
                               :ems_ref => resource_group_ref)
            end

            it "creates a resource group" do
              test_targeted_refresh([resource_group], 'resource_group') do
                assert_resource_counts
                assert_specific_resource_group
              end
            end
          end

          describe "on populated database" do
            context "objects are updated on remote server" do
              let(:vm_ref)             { "/subscriptions/#{subscription}/resourcegroups/#{resource_group_name}/providers/microsoft.compute/virtualmachines/#{vm_name}".downcase }
              let(:network_ref)        { "/subscriptions/#{subscription}/resourcegroups/#{resource_group_name}/providers/microsoft.network/virtualnetworks/#{network_name}".downcase }
              let(:network_port_ref)   { "/subscriptions/#{subscription}/resourcegroups/#{resource_group_name}/providers/microsoft.network/networkinterfaces/#{port_name}".downcase }
              let(:security_group_ref) { "/subscriptions/#{subscription}/resourcegroups/#{resource_group_name}/providers/microsoft.network/networksecuritygroups/#{security_group_name}".downcase }

              let!(:resource_group) do
                FactoryBot.create(:resource_group_azure_stack,
                                  :ems_id  => ems.id,
                                  :ems_ref => resource_group_ref,
                                  :name    => "dummy")
              end
              let!(:vm) do
                FactoryBot.create(:vm_azure_stack,
                                  :ems_id          => ems.id,
                                  :ems_ref         => vm_ref,
                                  :name            => "dummy",
                                  :raw_power_state => "dummy",
                                  :resource_group  => resource_group)
              end
              let!(:network) do
                FactoryBot.create(:cloud_network,
                                  :ems_id         => ems.network_manager.id,
                                  :ems_ref        => network_ref,
                                  :name           => "dummy",
                                  :resource_group => resource_group)
              end
              let!(:port) do
                FactoryBot.create(:network_port_azure_stack,
                                  :ems_id         => ems.network_manager.id,
                                  :ems_ref        => network_port_ref,
                                  :name           => "dummy",
                                  :mac_address    => "dummy",
                                  :resource_group => resource_group)
              end
              let!(:security_group) do
                FactoryBot.create(:security_group,
                                  :ems_id         => ems.network_manager.id,
                                  :ems_ref        => security_group_ref,
                                  :name           => "dummy",
                                  :resource_group => resource_group)
              end

              it "resource group is updated" do
                test_targeted_refresh([resource_group], 'resource_group') do
                  assert_updated(resource_group, :name => resource_group_name)
                  assert_updated(vm, :name            => vm_name,
                                     :raw_power_state => "PowerState/running",
                                     :flavor          => flavor)
                  assert_updated(network, :name => network_name)
                  assert_updated(port, :name => port_name, :mac_address => "001DD8B700FC")
                  assert_updated(security_group, :name => security_group_name)
                end
              end
            end

            context "objects are deleted from the remote server" do
              let(:resource_group) do
                FactoryBot.create(:resource_group_azure_stack,
                                  :ems_id  => ems.id,
                                  :ems_ref => "/subscriptions/#{subscription}/resourcegroups/nonexistent")
              end

              it "resource group is deleted" do
                test_targeted_refresh([resource_group], "resource_group_deleted", :repeat => 1) do
                  assert_deleted(resource_group)
                end
              end
            end
          end
        end
      end
    end
  end

  def test_targeted_refresh(targets, cassette, repeat: 2)
    targets = inventory_refresh_targets(targets)
    repeat.times do # Run twice to verify that a second run with existing data does not change anything
      EmsRefresh.queue_refresh(targets)
      expect(MiqQueue.where(:method_name => 'refresh').count).to eq 1
      refresh_job = MiqQueue.where(:method_name => 'refresh').first

      vcr_with_auth("#{described_class.name.underscore}_targeted/#{api_version}-#{cassette}") do
        status, message, result = refresh_job.deliver
        refresh_job.delivered(status, message, result)
        expect(:status => status, :msg => message).not_to include(:status => 'error')
      end

      ems.reload
      yield
    end
  end

  def inventory_refresh_targets(targets)
    targets.map do |target|
      case target
      when InventoryRefresh::Target
        return target
      when ResourceGroup
        association = :resource_groups
      end

      InventoryRefresh::Target.new(
        :manager     => ems,
        :association => association,
        :manager_ref => { :ems_ref => target.ems_ref }
      )
    end
  end

  def assert_resource_counts
    expect(ResourceGroup.count).to eq(1)
    expect(Vm.count).to eq(1)
    expect(CloudNetwork.count).to eq(1)
    expect(CloudSubnet.count).to eq(1)
    expect(NetworkPort.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
  end

  def assert_specific_resource_group
    resource_group = ResourceGroup.find_by(:name => resource_group_name)
    expect(resource_group).not_to be_nil
    expect(ems_ref_suffix(resource_group.ems_ref)).to eq('')
    expect(resource_group.name).to eq(resource_group_name)

    expect(resource_group.vms.size).to eq(1)
    expect(resource_group.cloud_networks.size).to eq(1)
    expect(resource_group.network_ports.size).to eq(1)
    expect(resource_group.security_groups.size).to eq(1)
  end

  def assert_updated(obj, attrs)
    obj.reload
    expect(obj).to have_attributes(attrs)
  end

  def assert_deleted(obj)
    expect { obj.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
