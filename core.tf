################################################################################
# Net
################################################################################

resource "outscale_net" "this" {
  ip_range = var.ip_range
  tenancy  = var.tenancy

  dynamic "tags" {
    for_each = local.common_tags
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# Subnets
################################################################################

resource "outscale_subnet" "this" {
  for_each = var.subnets

  net_id         = outscale_net.this.net_id
  ip_range       = each.value.ip_range
  subregion_name = each.value.subregion_name

  dynamic "tags" {
    for_each = merge(local.common_tags, { Name = each.key })
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

################################################################################
# DHCP Options
################################################################################

resource "outscale_dhcp_option" "this" {
  count = local.enable_dhcp ? 1 : 0

  domain_name         = var.dhcp_domain_name
  domain_name_servers = var.dhcp_domain_name_servers
  ntp_servers         = var.dhcp_ntp_servers
  log_servers         = var.dhcp_log_servers

  dynamic "tags" {
    for_each = local.common_tags
    content {
      key   = tags.key
      value = tags.value
    }
  }
}

resource "outscale_net_attributes" "this" {
  count = local.enable_dhcp ? 1 : 0

  net_id              = outscale_net.this.net_id
  dhcp_options_set_id = outscale_dhcp_option.this[0].dhcp_options_set_id
}
