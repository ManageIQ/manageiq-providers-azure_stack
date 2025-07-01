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
  config.default_cassette_options = { :match_requests_on => [:method, :path] }
  config.before_playback do |interaction|
    interaction.filter!('AZURE_STACK_HOST', 'azure_stack_host')
  end
  config.filter_sensitive_data('AZURE_STACK_TOKEN') do |interaction|
    if (auth_header = interaction.request.headers['Authorization'])
      auth_header.first.sub(/^Bearer /, '')
    end
  end

  VcrSecrets.define_all_cassette_placeholders(config, :azure_stack)
end
