class ManageIQ::Providers::AzureStack::Inventory::Collector::TargetCollection < ManageIQ::Providers::AzureStack::Inventory::Collector
  require_nested :V2018_03_01
  require_nested :V2017_03_09

  def initialize(manager, target)
    super

    parse_targets!
    infer_related_ems_refs!

    # Reset the target cache, so we can access new targets inside
    target.manager_refs_by_association_reset
  end

  # ##################################
  # Target collection for CloudManager
  # ##################################
  def resource_groups
    return @resource_groups unless @resource_groups.nil?

    refs = references(:resource_groups) || []
    @resource_groups = refs.map { |ems_ref| resource_group(ems_ref) }.compact
  end

  def resource_group(ems_ref)
    group_name = resource_group_name(ems_ref)
    safe_call { azure_resources.resource_groups.get(group_name) }
  end

  def resources(group_ems_ref)
    group_name = resource_group_name(group_ems_ref)
    safe_call { azure_resources.resources.list_by_resource_group(group_name) } || []
  end

  def vms
    return [] if (refs = references(:vms)).blank?

    refs.map { |ems_ref| vm(ems_ref) }.compact
  end

  def vm(ems_ref)
    group_name, vm_name = resource_group_and_resource_name(ems_ref)

    safe_call do
      azure_compute.virtual_machines.get(group_name, vm_name).tap do |vm|
        vm.instance_view = azure_compute.virtual_machines.instance_view(group_name, vm_name)
      end
    end
  end

  def flavors
    []
  end

  def orchestration_stacks
    []
  end

  # ####################################
  # Target collection for NetworkManager
  # ####################################
  def networks
    return [] if (refs = references(:cloud_networks)).blank?

    refs.map { |ems_ref| network(ems_ref) }.compact
  end

  def network(ems_ref)
    group_name, network_name = resource_group_and_resource_name(ems_ref)
    safe_call { azure_network.virtual_networks.get(group_name, network_name) }
  end

  def network_ports
    return [] if (refs = references(:network_ports)).blank?

    refs.map { |ems_ref| network_port(ems_ref) }.compact
  end

  def network_port(ems_ref)
    group_name, port_name = resource_group_and_resource_name(ems_ref)
    safe_call { azure_network.network_interfaces.get(group_name, port_name) }
  end

  def security_groups
    return [] if (refs = references(:security_groups)).blank?

    refs.map { |ems_ref| security_group(ems_ref) }.compact
  end

  def security_group(ems_ref)
    group_name, security_group_name = resource_group_and_resource_name(ems_ref)
    safe_call { azure_network.network_security_groups.get(group_name, security_group_name) }
  end

  private

  def safe_call
    yield
  rescue MsRestAzure::AzureOperationError => err
    $azure_stack_log.error("error: #{err}")
    nil
  end

  def parse_targets!
    target.targets.each do |target|
      case target
      when ResourceGroup
        add_target!(:resource_group, target.ems_ref)
      end
    end
  end

  def infer_related_ems_refs!
    if references(:resource_groups).present?
      infer_related_resource_groups_refs_db!
      infer_related_resource_groups_refs_api!
    end
  end

  def infer_related_resource_groups_refs_db!
    changed_resource_groups = manager.resource_groups
                                     .where(:ems_ref => references(:resource_groups))
    changed_resource_groups.each do |resource_group|
      resource_group.vms.each             { |vm| add_target!(:vms, vm.ems_ref) }
      resource_group.cloud_networks.each  { |network| add_target!(:cloud_networks, network.ems_ref) }
      resource_group.network_ports.each   { |port| add_target!(:network_ports, port.ems_ref) }
      resource_group.security_groups.each { |sg| add_target!(:security_groups, sg.ems_ref) }
    end
  end

  def infer_related_resource_groups_refs_api!
    resource_groups.each do |resource_group|
      group_ref = resource_group.id.downcase

      resources(group_ref).each do |resource|
        add_target!(type_to_association(resource.type), resource.id.downcase)
      end
    end
  end

  def type_to_association(type)
    case type.downcase
    when "microsoft.compute/virtualmachines"
      :vms
    when "microsoft.network/networkinterfaces"
      :network_ports
    when "microsoft.network/networksecuritygroups"
      :security_groups
    when "microsoft.network/virtualnetworks"
      :cloud_networks
    end
  end
end
