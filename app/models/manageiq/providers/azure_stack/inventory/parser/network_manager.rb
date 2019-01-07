class ManageIQ::Providers::AzureStack::Inventory::Parser::NetworkManager < ManageIQ::Providers::AzureStack::Inventory::Parser
  def parse
    log_header = "Collecting data for EMS : [#{collector.manager.name}] id: [#{collector.manager.id}]"
    $azure_stack_log.info("#{log_header}...")

    security_groups

    $azure_stack_log.info("#{log_header}...Complete")
  end

  def security_groups
    collector.security_groups.each do |security_group|
      persister.security_groups.build(
        :name    => security_group.name,
        :ems_ref => security_group.id.downcase
      )
    end
  end
end
