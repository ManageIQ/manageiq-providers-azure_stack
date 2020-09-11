EMS_REF_PREFIX = %r{^/subscriptions/[^/]+/resourcegroups/[^/]+}.freeze

# Extract common prefix from the ems_ref.
# Many Azure Stack ids start with id of resource group so we can extract it
# early to have more readable test assertions later.
def ems_ref_suffix(ems_ref)
  expect(ems_ref).to match(EMS_REF_PREFIX) # fail if prefix not there, don't go continue silently
  ems_ref.sub(EMS_REF_PREFIX, '')
end
