class ManageIQ::Providers::AzureStack::CloudManager::EventTargetParser
  include ManageIQ::Providers::AzureStack::EmsRefMixin

  attr_reader :ems_event

  # @param ems_event [EmsEvent] EmsEvent object
  def initialize(ems_event)
    @ems_event = ems_event
  end

  # Parses all targets that are present in the EmsEvent given in the initializer
  #
  # @return [Array] Array of InventoryRefresh::Target objects
  def parse
    parse_ems_event_targets(ems_event)
  end

  # Parses list of InventoryRefresh::Target out of the given EmsEvent
  #
  # @param event [EmsEvent] EmsEvent object
  # @return [Array] Array of InventoryRefresh::Target objects
  def parse_ems_event_targets(event)
    target_collection = InventoryRefresh::TargetCollection.new(:manager => event.ext_management_system, :event => event)

    parse_event_target(target_collection, event.full_data)
    targets = target_collection.targets

    msg = "Mapped [#{event[:event_type]}] to refresh targets #{targets.map(&:manager_ref)}"
    $azure_stack_log.debug(msg)

    targets
  end

  def parse_event_target(target_collection, event_data)
    id = event_data[:resource_id]
    return unless id && (group_id = resource_group_id(id))

    target_collection.add_target(:association => :resource_groups, :manager_ref => {:ems_ref => group_id})
  end
end
