describe ManageIQ::Providers::AzureStack::NetworkManager do
  let(:ems)         { FactoryBot.create(:ems_azure_stack_with_authentication, :provider_region => 'region') }
  let(:ems_network) { ems.network_manager }

  it '#ems_type' do
    expect(described_class.ems_type).to eq('azure_stack_network')
  end

  it '#description' do
    expect(described_class.description).to eq('Azure Stack Network')
  end

  it '#hostname_required?' do
    expect(described_class.hostname_required?).to eq(false)
  end

  it '#display_name' do
    expect(described_class.display_name).to eq('Network Manager (Microsoft Azure Stack)')
  end

  it '.provider_region is delegated' do
    expect(ems.provider_region).to eq('region')
    expect(ems_network.provider_region).to eq('region')

    ems.provider_region = 'other-region'
    ems.save!
    ems_network.reload

    expect(ems.provider_region).to eq('other-region')
    expect(ems_network.provider_region).to eq('other-region')
  end
end
