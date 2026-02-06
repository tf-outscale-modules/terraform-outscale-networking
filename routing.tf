################################################################################
# Route Tables
################################################################################

resource "outscale_route_table" "this" {
  for_each = var.route_tables

  net_id = outscale_net.this.net_id

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Route Table Links (Subnet Associations)
################################################################################

resource "outscale_route_table_link" "this" {
  for_each = local.route_table_subnet_links

  route_table_id = outscale_route_table.this[each.value.route_table_key].route_table_id
  subnet_id      = outscale_subnet.this[each.value.subnet_key].subnet_id
}

################################################################################
# Main Route Table Link
################################################################################

resource "outscale_main_route_table_link" "this" {
  count = var.main_route_table_key != null ? 1 : 0

  net_id         = outscale_net.this.net_id
  route_table_id = outscale_route_table.this[var.main_route_table_key].route_table_id
}

################################################################################
# Routes — Gateway Target
################################################################################

resource "outscale_route" "gateway" {
  for_each = local.routes_gateway

  route_table_id       = outscale_route_table.this[each.value.route_table_key].route_table_id
  destination_ip_range = each.value.destination_ip_range
  gateway_id           = each.value.gateway_id
}

################################################################################
# Routes — NAT Service Target
################################################################################

resource "outscale_route" "nat" {
  for_each = local.routes_nat

  route_table_id       = outscale_route_table.this[each.value.route_table_key].route_table_id
  destination_ip_range = each.value.destination_ip_range
  nat_service_id       = outscale_nat_service.this[each.value.nat_key].nat_service_id
}

################################################################################
# Routes — Net Peering Target
################################################################################

resource "outscale_route" "peering" {
  for_each = local.routes_peering

  route_table_id       = outscale_route_table.this[each.value.route_table_key].route_table_id
  destination_ip_range = each.value.destination_ip_range
  net_peering_id       = outscale_net_peering.this[each.value.peering_key].net_peering_id
}

################################################################################
# Routes — NIC Target
################################################################################

resource "outscale_route" "nic" {
  for_each = local.routes_nic

  route_table_id       = outscale_route_table.this[each.value.route_table_key].route_table_id
  destination_ip_range = each.value.destination_ip_range
  nic_id               = outscale_nic.this[each.value.nic_key].nic_id
}
