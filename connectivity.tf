################################################################################
# Internet Service
################################################################################

resource "outscale_internet_service" "this" {
  count = var.enable_internet_service ? 1 : 0

  dynamic "tags" {
    for_each = local.common_tags
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

resource "outscale_internet_service_link" "this" {
  count = var.enable_internet_service ? 1 : 0

  internet_service_id = outscale_internet_service.this[0].internet_service_id
  net_id              = outscale_net.this.net_id
}

################################################################################
# Public IPs — Auto-created for NAT Services
################################################################################

resource "outscale_public_ip" "nat" {
  for_each = var.enable_nat_services ? var.nat_services : {}

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = "${each.key}-nat" })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Public IPs — Standalone
################################################################################

resource "outscale_public_ip" "this" {
  for_each = var.public_ips

  dynamic "tags" {
    for_each = merge(local.common_tags, each.value.tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# NAT Services
################################################################################

resource "outscale_nat_service" "this" {
  for_each = var.enable_nat_services ? var.nat_services : {}

  subnet_id    = outscale_subnet.this[each.value.subnet_key].subnet_id
  public_ip_id = outscale_public_ip.nat[each.key].public_ip_id

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }

  depends_on = [outscale_internet_service_link.this]
}

################################################################################
# Net Peerings
################################################################################

resource "outscale_net_peering" "this" {
  for_each = var.enable_net_peerings ? var.net_peerings : {}

  accepter_net_id = each.value.accepter_net_id
  source_net_id   = outscale_net.this.net_id

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

resource "outscale_net_peering_acceptation" "this" {
  for_each = {
    for k, v in var.net_peerings : k => v
    if var.enable_net_peerings && v.auto_accept
  }

  net_peering_id = outscale_net_peering.this[each.key].net_peering_id
}

################################################################################
# Net Access Points
################################################################################

resource "outscale_net_access_point" "this" {
  for_each = var.enable_net_access_points ? var.net_access_points : {}

  net_id       = outscale_net.this.net_id
  service_name = each.value.service_name
  route_table_ids = [
    for rt_key in each.value.route_table_keys : outscale_route_table.this[rt_key].route_table_id
  ]

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}
