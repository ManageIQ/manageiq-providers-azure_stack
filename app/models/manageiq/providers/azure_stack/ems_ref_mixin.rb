module ManageIQ::Providers::AzureStack::EmsRefMixin
  extend ActiveSupport::Concern

  def resource_group_name(ems_ref)
    if (match = ems_ref.match(%r{/subscriptions/[^/]+/resourceGroups/(?<name>[^/]+)(/.+)?}i))
      match[:name].downcase
    end
  end

  def resource_group_id(ems_ref)
    if (match = ems_ref.match(%r{(?<id>/subscriptions/[^/]+/resourceGroups/[^/]+)/.+}i))
      match[:id].downcase
    end
  end

  # returns name of the resource group and name of the resource in an array
  def resource_group_and_resource_name(ems_ref)
    if (match = ems_ref.match(%r{/subscriptions/[^/]+/resourceGroups/(?<group_name>[^/]+).+/(?<name>[^/]+)}i))
      [match[:group_name], match[:name]].each(&:downcase)
    end
  end
end
