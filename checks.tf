check "nat_services_need_internet_service" {
  assert {
    condition     = !var.enable_nat_services || var.enable_internet_service
    error_message = "enable_nat_services is true but enable_internet_service is false: NAT services need an Internet Service attached to the Net, from this module or created elsewhere."
  }
}

check "routes_have_target" {
  assert {
    condition = alltrue([
      for k, v in local.all_routes :
      v.use_internet_service || v.gateway_id != null || v.nat_key != null || v.peering_key != null || v.nic_key != null
    ])
    error_message = "A route in route_tables sets no target (use_internet_service, gateway_id, nat_key, peering_key or nic_key) and creates nothing."
  }
}
