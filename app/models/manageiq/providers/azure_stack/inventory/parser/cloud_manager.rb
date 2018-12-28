class ManageIQ::Providers::AzureStack::Inventory::Parser::CloudManager < ManageIQ::Providers::AzureStack::Inventory::Parser
  def parse
    log_header = "Collecting data for EMS : [#{collector.manager.name}] id: [#{collector.manager.id}]"
    $azure_stack_log.info("#{log_header}...")

    resource_groups

    $azure_stack_log.info("#{log_header}...Complete")
  end

  def resource_groups
    collector.resource_groups.each do |resource_group|
      persister.resource_groups.build(
        :name    => resource_group.name,
        :ems_ref => resource_group.id.downcase
      )
    end
  end
end
