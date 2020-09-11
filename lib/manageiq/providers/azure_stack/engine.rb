module ManageIQ
  module Providers
    module AzureStack
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::AzureStack

        config.autoload_paths << root.join('lib').to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Azure Stack Provider')
        end
      end
    end
  end
end
