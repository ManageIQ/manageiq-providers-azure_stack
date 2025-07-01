describe ManageIQ::Providers::AzureStack::CloudManager do
  let(:url)           { "https://#{VcrSecrets.azure_stack.host}" }
  let(:tenant)        { VcrSecrets.azure_stack.tenant }
  let(:userid)        { VcrSecrets.azure_stack.userid }
  let(:password)      { VcrSecrets.azure_stack.password }
  let(:subscription)  { VcrSecrets.azure_stack.subscription }

  supported_api_versions do |api_version|
    describe '#raw_connect' do
      let(:args) { [url, tenant, userid, password, subscription, :Resources, api_version] }

      it 'when successful' do
        vcr_with_auth("#{described_class.name.underscore}/#{api_version}/raw_connect-success") do
          described_class.raw_connect(*args, :validate => true)
        end
      end

      context 'when bad tenant id' do
        let(:tenant) { 'bad-value' }
        it 'raises MIQ error' do
          VCR.use_cassette("#{described_class.name.underscore}/#{api_version}/raw_connect-bad_tenant") do
            expect { described_class.raw_connect(*args, :validate => true) }.to raise_error(MiqException::MiqInvalidCredentialsError)
          end
        end
      end

      context 'when bad username and password' do
        let(:userid)   { 'bad-value' }
        let(:password) { 'bad-value' }
        it 'raises MIQ error' do
          VCR.use_cassette("#{described_class.name.underscore}/#{api_version}/raw_connect-bad_username_password") do
            expect { described_class.raw_connect(*args, :validate => true) }.to raise_error(MiqException::MiqInvalidCredentialsError)
          end
        end
      end

      context 'when bad subscription' do
        let(:subscription) { 'bad-value' }
        it 'raises MIQ error' do
          vcr_with_auth("#{described_class.name.underscore}/#{api_version}/raw_connect-bad_subscription") do
            expect { described_class.raw_connect(*args, :validate => true) }.to raise_error(MiqException::MiqInvalidCredentialsError)
          end
        end
      end
    end
  end
end
