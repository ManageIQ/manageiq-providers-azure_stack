# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/azure_stack/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-azure_stack"
  spec.version       = ManageIQ::Providers::AzureStack::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ plugin for the Azure Stack provider."
  spec.description   = "ManageIQ plugin for the Azure Stack provider."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-azure_stack"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'azure_mgmt_compute', '0.18.3'
  spec.add_runtime_dependency 'azure_mgmt_monitor', '0.17.1'
  spec.add_runtime_dependency 'azure_mgmt_network', '0.18.2'
  spec.add_runtime_dependency 'azure_mgmt_resources', '0.17.2'
  spec.add_runtime_dependency 'ms_rest_azure', '0.11.2'

  spec.add_development_dependency "simplecov"
end
