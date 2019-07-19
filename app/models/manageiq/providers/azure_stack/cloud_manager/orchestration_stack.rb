class ManageIQ::Providers::AzureStack::CloudManager::OrchestrationStack < ManageIQ::Providers::CloudManager::OrchestrationStack
  require_nested :Status

  def self.raw_create_stack(ems, stack_name, template, options = {})
    create_or_update_stack(ems, stack_name, template, options)
  rescue => err
    $azure_stack_log.error("stack=[#{stack_name}], error: #{err}")
    raise MiqException::MiqOrchestrationProvisionError, err.to_s, err.backtrace
  end

  def raw_update_stack(template, options)
    self.class.create_or_update_stack(ext_management_system, name, template, options)
  rescue => err
    $azure_stack_log.error("stack=[#{name}], error: #{err}")
    raise MiqException::MiqOrchestrationUpdateError, err.to_s, err.backtrace
  end

  def raw_delete_stack
    $azure_stack_log.debug("Deleting orchestration stack (ems=#{ext_management_system.name}, stack_name=#{name})")
    ext_management_system.with_provider_connection(:service => :Resources) do |client|
      # TODO(miha-plesko): this only deletes the deployment leaving all resources still there. Need to remove those too.
      client.deployments.delete(resource_group, name)
    end
  rescue => err
    $azure_stack_log.error("stack=[#{name}], error: #{err}")
    raise MiqException::MiqOrchestrationDeleteError, err.to_s, err.backtrace
  end

  def raw_status
    ext_management_system.with_provider_connection(:service => :Resources) do |client|
      state = client.deployments.get(resource_group, name).properties.provisioning_state.downcase
      Status.new(state, state == 'succeeded' ? 'OK' : failure_reason(client))
    end
  rescue MsRestAzure::AzureOperationError => err
    $azure_stack_log.error("stack=[#{name}], error: #{err}")
    raise MiqException::MiqOrchestrationStackNotExistError, err.to_s, err.backtrace if err&.error_code == 'DeploymentNotFound'

    raise MiqException::MiqOrchestrationStatusError, err.to_s, err.backtrace
  rescue => err
    $azure_stack_log.error("stack=[#{name}], error: #{err}")
    raise MiqException::MiqOrchestrationStatusError, err.to_s, err.backtrace
  end

  def self.build_ems_ref(ems, resource_group, stack_name)
    "/subscriptions/#{ems.subscription}"\
    "/resourcegroups/#{resource_group}"\
    "/providers/microsoft.resources/deployments/#{stack_name}".downcase
  end

  def self.display_name(number = 1)
    n_('Orchestration Stack (Microsoft AzureStack)', 'Orchestration Stacks (Microsoft AzureStack)', number)
  end

  def self.create_or_update_stack(ems, stack_name, template, options)
    $azure_stack_log.debug("Creating/Updating orchestration stack [ems=#{ems.name}, " \
      "stack_name=#{stack_name}, template=#{template.name}, options=#{options}]")
    ems.with_provider_connection(:service => :Resources) do |client|
      # Ensure resource group exists because deployment assumes existing one.
      client.resource_groups.create_or_update(
        options[:resource_group],
        client.model_classes.resource_group.new.tap { |g| g.location = ems.provider_region }
      )
      # Deploy into the resource group.
      deployment = client.model_classes.deployment.new
      deployment.properties = client.model_classes.deployment_properties.new.tap do |props|
        props.template = JSON.parse(template.content)
        props.mode = options[:mode]
        props.parameters = options[:parameters].transform_values! { |v| { 'value' => v } }
      end

      client.deployments.create_or_update_async(options[:resource_group], stack_name, deployment)
      build_ems_ref(ems, options[:resource_group], stack_name)
    end
  end

  private

  def failure_reason(client)
    operations = client.deployment_operations.list(resource_group, name)
    msg = operations.detect { |op| op.properties.provisioning_state.downcase != 'succeeded' }&.properties&.status_message
    return nil unless msg && (reason = msg['error'])

    "[#{reason['code']}][#{reason['target']}] #{reason['message']}"
  end
end
