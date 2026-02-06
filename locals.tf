locals {
  common_tags = merge(
    { ManagedBy = "terraform" },
    var.tags,
  )

  enable_dhcp = anytrue([
    var.dhcp_domain_name != null,
    var.dhcp_domain_name_servers != null,
    var.dhcp_ntp_servers != null,
    var.dhcp_log_servers != null,
  ])

  # Flatten route table -> subnet associations for route_table_link
  route_table_subnet_links = merge([
    for rt_key, rt in var.route_tables : {
      for sk in rt.subnet_keys : "${rt_key}-${sk}" => {
        route_table_key = rt_key
        subnet_key      = sk
      }
    }
  ]...)

  # Flatten route table -> routes, split by target type
  all_routes = merge([
    for rt_key, rt in var.route_tables : {
      for idx, route in rt.routes : "${rt_key}-${idx}" => merge(route, {
        route_table_key = rt_key
      })
    }
  ]...)

  routes_gateway = {
    for k, v in local.all_routes : k => v if v.gateway_id != null || v.use_internet_service
  }

  routes_nat = {
    for k, v in local.all_routes : k => v if v.nat_key != null
  }

  routes_peering = {
    for k, v in local.all_routes : k => v if v.peering_key != null
  }

  routes_nic = {
    for k, v in local.all_routes : k => v if v.nic_key != null
  }
}
