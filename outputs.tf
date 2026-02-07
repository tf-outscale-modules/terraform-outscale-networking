################################################################################
# Core
################################################################################

output "net_id" {
  description = "The ID of the Net"
  value       = outscale_net.this.net_id
}

output "subnet_ids" {
  description = "Map of subnet key to subnet ID"
  value       = { for k, v in outscale_subnet.this : k => v.subnet_id }
}

output "dhcp_options_set_id" {
  description = "The ID of the DHCP options set (if created)"
  value       = try(outscale_dhcp_option.this[0].dhcp_options_set_id, null)
}

################################################################################
# Connectivity
################################################################################

output "internet_service_id" {
  description = "The ID of the Internet Service (if created)"
  value       = try(outscale_internet_service.this[0].internet_service_id, null)
}

output "nat_service_ids" {
  description = "Map of NAT service key to NAT service ID"
  value       = { for k, v in outscale_nat_service.this : k => v.nat_service_id }
}

output "public_ip_ids" {
  description = "Map of public IP key to public IP allocation ID (standalone public IPs only)"
  value       = { for k, v in outscale_public_ip.this : k => v.public_ip_id }
}

output "public_ips" {
  description = "Map of public IP key to public IP address (standalone public IPs only)"
  value       = { for k, v in outscale_public_ip.this : k => v.public_ip }
}

output "net_peering_ids" {
  description = "Map of peering key to Net peering ID"
  value       = { for k, v in outscale_net_peering.this : k => v.net_peering_id }
}

output "net_access_point_ids" {
  description = "Map of access point key to Net access point ID"
  value       = { for k, v in outscale_net_access_point.this : k => v.net_access_point_id }
}

################################################################################
# Routing
################################################################################

output "route_table_ids" {
  description = "Map of route table key to route table ID"
  value       = { for k, v in outscale_route_table.this : k => v.route_table_id }
}

################################################################################
# Services
################################################################################

output "load_balancer_dns_names" {
  description = "Map of load balancer key to DNS name"
  value       = { for k, v in outscale_load_balancer.this : k => v.dns_name }
}

output "nic_ids" {
  description = "Map of NIC key to NIC ID"
  value       = { for k, v in outscale_nic.this : k => v.nic_id }
}
