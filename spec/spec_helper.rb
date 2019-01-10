if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

EMS_REF_PREFIX = %r{^/subscriptions/[^/]+/resourcegroups/[^/]+}.freeze

# Uncomment in case you use vcr cassettes
VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::AzureStack::Engine.root, 'spec/vcr_cassettes')
  config.before_playback do |interaction|
    interaction.filter!('AZURE_STACK_HOST', 'azure_stack_host')
  end
  config.filter_sensitive_data('AZURE_STACK_TOKEN') do |interaction|
    if (auth_header = interaction.request.headers['Authorization'])
      auth_header.first.sub(/^Bearer /, '')
    end
  end
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[ManageIQ::Providers::AzureStack::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

def vcr_with_auth(casette)
  VCR.use_cassette('obtain_endpoints', :allow_unused_http_interactions => true) do
    VCR.use_cassette('obtain_token', :allow_playback_repeats => false, :allow_unused_http_interactions => true) do
      VCR.use_cassette(casette, :allow_unused_http_interactions => false) do
        yield
      end
    end
  end
end

def supported_api_versions(&block)
  ManageIQ::Providers::AzureStack::CloudManager::SUPPORTED_API_VERSIONS.each do |api_version|
    context api_version do
      let(:api_version) { api_version }
      class_exec(api_version, &block)
    end
  end
end

# Extract common prefix from the ems_ref.
# Many Azure Stack ids start with id of resource group so we can extract it
# early to have more readable test assertions later.
def ems_ref_suffix(ems_ref)
  expect(ems_ref).to match(EMS_REF_PREFIX) # fail if prefix not there, don't go continue silently
  ems_ref.sub(EMS_REF_PREFIX, '')
end
