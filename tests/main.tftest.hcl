################################################################################
# Variables for all test runs
################################################################################

variables {
  ip_range = "10.0.0.0/16"
  subnets = {
    public_a = {
      ip_range       = "10.0.1.0/24"
      subregion_name = "eu-west-2a"
    }
    public_b = {
      ip_range       = "10.0.2.0/24"
      subregion_name = "eu-west-2b"
    }
  }
}

################################################################################
# Core Resources
################################################################################

run "creates_net" {
  command = plan

  assert {
    condition     = outscale_net.this.ip_range == "10.0.0.0/16"
    error_message = "Net ip_range should be 10.0.0.0/16"
  }

  assert {
    condition     = outscale_net.this.tenancy == "default"
    error_message = "Net tenancy should default to 'default'"
  }
}

run "creates_subnets" {
  command = plan

  assert {
    condition     = length(outscale_subnet.this) == 2
    error_message = "Expected 2 subnets to be created"
  }

  assert {
    condition     = outscale_subnet.this["public_a"].ip_range == "10.0.1.0/24"
    error_message = "Subnet public_a should have ip_range 10.0.1.0/24"
  }

  assert {
    condition     = outscale_subnet.this["public_b"].subregion_name == "eu-west-2b"
    error_message = "Subnet public_b should be in eu-west-2b"
  }
}

################################################################################
# DHCP — Skipped When Disabled
################################################################################

run "skips_dhcp_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_dhcp_option.this) == 0
    error_message = "DHCP options should not be created when no DHCP variables are set"
  }

  assert {
    condition     = length(outscale_net_attributes.this) == 0
    error_message = "Net attributes should not be created when DHCP is disabled"
  }
}

################################################################################
# DHCP — Created When Enabled
################################################################################

run "creates_dhcp_when_enabled" {
  command = plan

  variables {
    dhcp_domain_name         = "test.internal"
    dhcp_domain_name_servers = ["10.0.0.2"]
  }

  assert {
    condition     = length(outscale_dhcp_option.this) == 1
    error_message = "DHCP options should be created when dhcp_domain_name is set"
  }

  assert {
    condition     = outscale_dhcp_option.this[0].domain_name == "test.internal"
    error_message = "DHCP domain_name should be 'test.internal'"
  }

  assert {
    condition     = length(outscale_net_attributes.this) == 1
    error_message = "Net attributes should be created to link DHCP options"
  }
}

################################################################################
# Connectivity — Skipped When Disabled
################################################################################

run "skips_internet_service_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_internet_service.this) == 0
    error_message = "Internet service should not be created when enable_internet_service is false"
  }

  assert {
    condition     = length(outscale_internet_service_link.this) == 0
    error_message = "Internet service link should not be created when disabled"
  }
}

run "skips_nat_services_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_nat_service.this) == 0
    error_message = "NAT services should not be created when enable_nat_services is false"
  }

  assert {
    condition     = length(outscale_public_ip.nat) == 0
    error_message = "NAT public IPs should not be created when NAT is disabled"
  }
}

run "skips_net_peerings_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_net_peering.this) == 0
    error_message = "Net peerings should not be created when enable_net_peerings is false"
  }
}

run "skips_net_access_points_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_net_access_point.this) == 0
    error_message = "Net access points should not be created when enable_net_access_points is false"
  }
}

################################################################################
# Connectivity — Created When Enabled
################################################################################

run "creates_internet_service_when_enabled" {
  command = plan

  variables {
    enable_internet_service = true
  }

  assert {
    condition     = length(outscale_internet_service.this) == 1
    error_message = "Internet service should be created when enabled"
  }

  assert {
    condition     = length(outscale_internet_service_link.this) == 1
    error_message = "Internet service link should be created when enabled"
  }
}

################################################################################
# Routing — Empty When No Route Tables Defined
################################################################################

run "skips_route_tables_when_empty" {
  command = plan

  assert {
    condition     = length(outscale_route_table.this) == 0
    error_message = "Route tables should not be created when route_tables is empty"
  }

  assert {
    condition     = length(outscale_route.gateway) == 0
    error_message = "Gateway routes should not be created when route_tables is empty"
  }

  assert {
    condition     = length(outscale_route.nat) == 0
    error_message = "NAT routes should not be created when route_tables is empty"
  }
}

################################################################################
# Routing — Created When Defined
################################################################################

run "creates_route_tables" {
  command = plan

  variables {
    enable_internet_service = true
    route_tables = {
      public = {
        subnet_keys = ["public_a", "public_b"]
        routes      = []
      }
    }
  }

  assert {
    condition     = length(outscale_route_table.this) == 1
    error_message = "Expected 1 route table to be created"
  }

  assert {
    condition     = length(outscale_route_table_link.this) == 2
    error_message = "Expected 2 route table links (one per subnet)"
  }
}

################################################################################
# Services — Skipped When Disabled
################################################################################

run "skips_load_balancers_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_load_balancer.this) == 0
    error_message = "Load balancers should not be created when enable_load_balancers is false"
  }
}

run "skips_nics_when_empty" {
  command = plan

  assert {
    condition     = length(outscale_nic.this) == 0
    error_message = "NICs should not be created when nics is empty"
  }
}

################################################################################
# Outputs
################################################################################

run "outputs_net_resource_planned" {
  command = plan

  assert {
    condition     = outscale_net.this.ip_range == "10.0.0.0/16"
    error_message = "Net resource should be planned with the correct ip_range"
  }
}

run "outputs_subnet_ids" {
  command = plan

  assert {
    condition     = length(output.subnet_ids) == 2
    error_message = "subnet_ids output should contain 2 entries"
  }
}

run "outputs_dhcp_null_when_disabled" {
  command = plan

  assert {
    condition     = output.dhcp_options_set_id == null
    error_message = "dhcp_options_set_id should be null when DHCP is disabled"
  }
}

run "outputs_internet_service_null_when_disabled" {
  command = plan

  assert {
    condition     = output.internet_service_id == null
    error_message = "internet_service_id should be null when disabled"
  }
}

run "outputs_empty_maps_when_disabled" {
  command = plan

  assert {
    condition     = length(output.nat_service_ids) == 0
    error_message = "nat_service_ids should be empty when disabled"
  }

  assert {
    condition     = length(output.route_table_ids) == 0
    error_message = "route_table_ids should be empty when no route tables defined"
  }

  assert {
    condition     = length(output.load_balancer_dns_names) == 0
    error_message = "load_balancer_dns_names should be empty when disabled"
  }

  assert {
    condition     = length(output.nic_ids) == 0
    error_message = "nic_ids should be empty when no NICs defined"
  }
}
