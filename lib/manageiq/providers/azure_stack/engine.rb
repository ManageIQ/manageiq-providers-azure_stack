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

        def self.init_loggers
          $azure_stack_log ||= Vmdb::Loggers.create_logger("azure_stack.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $azure_stack_log, :level_azure_stack)
        end
      end
    end
  end
end
