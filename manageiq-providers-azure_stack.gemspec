$:.push File.expand_path("../lib", __FILE__)

require "manageiq/providers/azure_stack/version"

Gem::Specification.new do |s|
  s.name        = "manageiq-providers-azure_stack"
  s.version     = ManageIQ::Providers::AzureStack::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-providers-azure_stack"
  s.summary     = "AzureStack Provider for ManageIQ"
  s.description = "AzureStack Provider for ManageIQ"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,config,lib}/**/*"]

  s.add_runtime_dependency 'azure_mgmt_compute', '0.18.3'
  s.add_runtime_dependency 'azure_mgmt_monitor', '0.17.1'
  s.add_runtime_dependency 'azure_mgmt_network', '0.18.2'
  s.add_runtime_dependency 'azure_mgmt_resources', '0.17.2'
  s.add_runtime_dependency 'ms_rest_azure', '0.11.2'

  s.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  s.add_development_dependency "simplecov"
end
