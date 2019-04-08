module ManageIQ::Providers::AzureStack::EmsRefMixin
  extend ActiveSupport::Concern

  def resource_group_name(ems_ref)
    if (match = ems_ref.match(%r{/subscriptions/[^/]+/resourceGroups/(?<name>[^/]+)/.+}i))
      match[:name].downcase
    end
  end

  def resource_group_id(ems_ref)
    if (match = ems_ref.match(%r{(?<id>/subscriptions/[^/]+/resourceGroups/[^/]+)/.+}i))
      match[:id].downcase
    end
  end
end
