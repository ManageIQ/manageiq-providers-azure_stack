class ManageIQ::Providers::AzureStack::CloudManager::OrchestrationTemplate < ::OrchestrationTemplate
  def format
    'json'.freeze
  end

  def parameter_groups
    [OrchestrationTemplate::OrchestrationParameterGroup.new(
      :label      => 'Parameters',
      :parameters => parameters
    )]
  end

  def parameters
    raw_parameters = JSON.parse(content)['parameters']
    (raw_parameters || {}).collect do |key, val|
      parameter = OrchestrationTemplate::OrchestrationParameter.new(
        :name          => key,
        :label         => key.titleize,
        :data_type     => val['type'],
        :default_value => val['defaultValue'],
        :hidden        => val['type'].casecmp('securestring').zero?,
        :required      => true
      )

      add_metadata(parameter, val['metadata'])
      add_allowed_values(parameter, val['allowedValues'])

      parameter
    end
  end

  def deployment_options(_manager_class = nil)
    super << resource_group_opt << new_resource_group_opt << mode_opt
  end

  def self.eligible_manager_types
    [ManageIQ::Providers::AzureStack::CloudManager]
  end

  # return the parsing error message if not valid JSON; otherwise nil
  def validate_format
    JSON.parse(content) && nil if content
  rescue JSON::ParserError => err
    err.message
  end

  def self.display_name(number = 1)
    n_('AzureStack Template', 'AzureStack Templates', number)
  end

  private

  def mode_opt
    description = 'Select deployment mode.'\
                  'WARNING: Complete mode will delete all resources from '\
                  'the group that are not in the template.'
    choices = {'Incremental' => 'Incremental', 'Complete' => 'Complete'}
    OrchestrationTemplate::OrchestrationParameter.new(
      :name          => 'deploy_mode',
      :label         => 'Mode',
      :data_type     => 'string',
      :description   => description,
      :default_value => 'Incremental',
      :required      => true,
      :constraints   => [OrchestrationTemplate::OrchestrationParameterAllowed.new(:allowed_values => choices)]
    )
  end

  def resource_group_opt
    OrchestrationTemplate::OrchestrationParameter.new(
      :name        => 'resource_group',
      :label       => 'Existing Resource Group',
      :data_type   => 'string',
      :description => 'Select an existing resource group for deployment',
      :constraints => [
        OrchestrationTemplate::OrchestrationParameterAllowedDynamic.new(
          :fqname => '/Cloud/Orchestration/Operations/Methods/Available_Resource_Groups'
        )
      ]
    )
  end

  def new_resource_group_opt
    OrchestrationTemplate::OrchestrationParameter.new(
      :name        => 'new_resource_group',
      :label       => '(or) New Resource Group',
      :data_type   => 'string',
      :description => 'Create a new resource group upon deployment',
      :constraints => [
        OrchestrationTemplate::OrchestrationParameterPattern.new(:pattern => '^[A-Za-z][A-Za-z0-9\-_]*$')
      ]
    )
  end

  def add_metadata(parameter, metadata)
    return unless metadata

    parameter.description = metadata['description']
  end

  def add_allowed_values(parameter, vals)
    return unless vals

    constraint = OrchestrationTemplate::OrchestrationParameterAllowed.new(:allowed_values => vals)
    parameter.constraints << constraint
  end
end
