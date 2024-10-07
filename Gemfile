# Declare your gem's dependencies in manageiq-providers-azure_stack.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# Load Gemfile with dependencies from manageiq
eval_gemfile(File.expand_path("spec/manageiq/Gemfile", __dir__))

gem 'azure_mgmt_compute', '~> 0.20', git: 'https://github.com/Fryguy/azure-sdk-for-ruby', branch: 'drop_unused', glob: 'management/azure_mgmt_compute/*.gemspec'
gem 'azure_mgmt_monitor', '~> 0.17', git: 'https://github.com/Fryguy/azure-sdk-for-ruby', branch: 'drop_unused', glob: 'management/azure_mgmt_monitor/*.gemspec'
gem 'azure_mgmt_network', '~> 0.24', git: 'https://github.com/Fryguy/azure-sdk-for-ruby', branch: 'drop_unused', glob: 'management/azure_mgmt_network/*.gemspec'
gem 'azure_mgmt_resources', '~> 0.18', git: 'https://github.com/Fryguy/azure-sdk-for-ruby', branch: 'drop_unused', glob: 'management/azure_mgmt_resources/*.gemspec'
