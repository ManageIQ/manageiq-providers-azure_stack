if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq/providers/azure_stack"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::AzureStack::Engine.root, 'spec/vcr_cassettes')

  config.before_playback do |interaction|
    interaction.filter!('AZURE_STACK_HOST', 'azure_stack_host')
  end
  config.default_cassette_options = { :match_requests_on => [:method, :path] }
  config.filter_sensitive_data('AZURE_STACK_TOKEN') do |interaction|
    if (auth_header = interaction.request.headers['Authorization'])
      auth_header.first.sub(/^Bearer /, '')
    end
  end
  config.define_cassette_placeholder(Rails.application.secrets.azure_stack_defaults[:host]) do
    Rails.application.secrets.azure_stack[:host]
  end
  config.define_cassette_placeholder(Rails.application.secrets.azure_stack_defaults[:tenant]) do
    Rails.application.secrets.azure_stack[:tenant]
  end
  config.define_cassette_placeholder(Rails.application.secrets.azure_stack_defaults[:subscription]) do
    Rails.application.secrets.azure_stack[:subscription]
  end
  config.define_cassette_placeholder(Rails.application.secrets.azure_stack_defaults[:userid]) do
    Rails.application.secrets.azure_stack[:userid]
  end
  config.define_cassette_placeholder(Rails.application.secrets.azure_stack_defaults[:password]) do
    Rails.application.secrets.azure_stack[:password]
  end
end
