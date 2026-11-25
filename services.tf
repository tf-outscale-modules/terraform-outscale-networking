################################################################################
# Load Balancers
################################################################################

resource "outscale_load_balancer" "this" {
  for_each = var.enable_load_balancers ? var.load_balancers : {}

  load_balancer_name = each.value.load_balancer_name
  load_balancer_type = each.value.load_balancer_type
  security_groups    = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null
  secured_cookies    = each.value.secured_cookies
  subregion_names    = each.value.subregion_names
  public_ip          = each.value.public_ip_key == null ? null : outscale_public_ip.this[each.value.public_ip_key].public_ip

  # null (not []) when empty: the provider treats an empty list as set and would conflict with subregion_names
  subnets = length(each.value.subnet_keys) > 0 ? [
    for sk in each.value.subnet_keys : outscale_subnet.this[sk].subnet_id
  ] : null

  dynamic "listeners" {
    for_each = each.value.listeners
    content {
      backend_port           = listeners.value.backend_port
      backend_protocol       = listeners.value.backend_protocol
      load_balancer_port     = listeners.value.load_balancer_port
      load_balancer_protocol = listeners.value.load_balancer_protocol
      server_certificate_id  = listeners.value.server_certificate_id
    }
  }

  dynamic "tags" {
    for_each = merge(local.common_tags, each.value.tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# NICs (Network Interface Cards)
################################################################################

resource "outscale_nic" "this" {
  for_each = var.nics

  subnet_id          = outscale_subnet.this[each.value.subnet_key].subnet_id
  description        = each.value.description
  security_group_ids = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null

  dynamic "private_ips" {
    for_each = each.value.private_ips
    content {
      private_ip = private_ips.value.private_ip
      is_primary = private_ips.value.is_primary
    }
  }

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}
