require 'ms_rest_azure'

describe ManageIQ::Providers::AzureStack::CloudManager do
  it '.ems_type' do
    expect(described_class.ems_type).to eq('azure_stack')
  end

  it '.description' do
    expect(described_class.description).to eq('Azure Stack')
  end

  it '.api_allowed_attributes' do
    expect(described_class.api_allowed_attributes).to eq(%w[azure_tenant_id])
  end

  it '::SUPPORTED_API_VERSIONS' do
    expect(described_class::SUPPORTED_API_VERSIONS).to eq(%w[V2017_03_09 V2018_03_01])
  end

  describe '.provider_region' do
    let(:region) { 'region' }
    let(:ems)    { FactoryBot.create(:ems_azure_stack_with_authentication, :provider_region => region) }

    it 'when stored in VMDB' do
      expect(ems.provider_region).to eq('region')
    end

    context 'when not in VMDB' do
      let(:region) { nil }
      let(:resp)   { double('resp', :resource_types => [double(:locations => %w[region])]) }

      it 'fetched via API' do
        expect(ems).to receive_message_chain(:connect, :providers, :get).and_return(resp)
        expect(ems.provider_region).to eq('region')
        ems.reload
        # Should be stored in VMDB now
        expect(ems.provider_region).to eq('region')
      end
    end
  end

  describe '.verify_credentials' do
    before    { allow(ems).to receive(:api_version_supported?).and_return(true) }
    let(:ems) { FactoryBot.create(:ems_azure_stack_with_authentication) }

    context 'when raw_connect errors' do
      before do
        expect(ems).to receive(:active_directory_settings).and_return(true)
        expect(described_class).to receive(:raw_connect).and_raise(MsRestAzure::AzureOperationError.new('BOOOM'))
      end

      it 'handled error is raised' do
        expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError)
      end
    end

    context 'when active_directory_settings errors' do
      before        { expect(Faraday).to receive(:new).and_return(faraday) }
      let(:faraday) { double('faraday').tap { |f| expect(f).to receive(:get).and_yield(req).and_return(response) } }
      let(:req) do
        double('req', :path= => nil, :params= => nil, :headers => {}, :options => double('opts', :timeout= => nil))
      end

      context 'because of non-json response' do
        let(:response) { double('resp', :body => 'invalid-json') }
        it 'handled error is raised' do
          expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError)
        end
      end

      context 'because of timeout' do
        let(:faraday) { double('faraday').tap { |f| expect(f).to receive(:get).and_raise(Faraday::ConnectionFailed.new('BOOOM')) } }
        it 'handled error is raised' do
          expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError)
        end
      end
    end

    context 'when validate_connection errors' do
      before do
        expect(ems).to receive(:connect).and_return(double('conn', :base_url => 'base.url'))
        expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      context 'because of timeout' do
        it 'handled error is raised' do
          expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError)
        end
      end
    end

    context 'when something goes terribly wrong' do
      before do
        expect(ems).to receive(:connect).and_raise(StandardError)
      end

      it 'original error is raised' do
        expect { ems.verify_credentials }.to raise_error(StandardError)
      end
    end
  end

  supported_api_versions do |api_version|
    describe '#raw_connect' do
      before { allow(described_class).to receive(:active_directory_settings_api) }
      let(:fake_ad_settings) { double('fake AD settings') }
      let(:fake_token)       { double('fake token', :get_authentication_header => '', :is_a? => true) }
      let(:args) do
        [
          'base.url',
          'tenant',
          'username',
          MiqPassword.encrypt('password'),
          'subscription',
          :Resources,
          api_version
        ]
      end

      it 'decrypts password' do
        expect(described_class).to receive(:token).with(anything, anything, 'password', anything).and_return(fake_token)
        described_class.raw_connect(*args)
      end

      it 'validates credentials if specified' do
        expect(described_class).to receive(:validate_connection)
        described_class.raw_connect(*args, :validate => true, :token => fake_token, :ad_settings => fake_ad_settings)
      end
    end

    describe '.connect' do
      let(:ems_options) { nil }
      let(:ems) do
        FactoryBot.create(
          :ems_azure_stack_with_authentication,
          :api_version     => api_version,
          :provider_region => 'westus',
          :options         => ems_options
        )
      end

      context 'with AD settings stored' do
        before { allow(described_class).to receive(:active_directory_settings_api) }
        let(:ems_options) do
          {
            :active_directory_settings => {
              :authentication_endpoint => 'https://auth.test',
              :token_audience          => 'https://token.audience',
            }
          }
        end

        it 'yields default service' do
          client = ems.connect
          expect(client.class.name).to eq("Azure::Resources::Profiles::#{api_version}::Mgmt::Client")
          expect(client.credentials.present?).to be_truthy
        end

        it 'yields resources service' do
          client = ems.connect(:service => :Resources)
          expect(client.class.name).to eq("Azure::Resources::Profiles::#{api_version}::Mgmt::Client")
          expect(client.credentials.present?).to be_truthy
        end

        it 'yields compute service' do
          client = ems.connect(:service => :Compute)
          expect(client.class.name).to eq("Azure::Compute::Profiles::#{api_version}::Mgmt::Client")
          expect(client.credentials.present?).to be_truthy
        end
      end
    end
  end
end
