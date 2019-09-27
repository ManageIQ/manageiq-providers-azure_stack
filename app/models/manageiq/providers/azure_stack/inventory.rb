class ManageIQ::Providers::AzureStack::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  # Default manager for building collector/parser/persister classes
  # when failed to get class name from refresh target automatically
  def self.default_manager_name
    'CloudManager'
  end

  # Sets the appropriate class of versioned collector for
  # CloudManager and NetworkManager targets
  def self.collector_class_for(ems, target = nil, manager_name = nil)
    target = ems if target.nil?
    manager_name = "#{target.class.name.demodulize}::#{ems.api_version}" if manager_name.nil?
    class_for(ems, target, 'Collector', manager_name)
  end
end
