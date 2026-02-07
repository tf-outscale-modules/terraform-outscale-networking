output "net_id" {
  description = "The ID of the Net"
  value       = module.networking.net_id
}

output "subnet_ids" {
  description = "Map of subnet key to subnet ID"
  value       = module.networking.subnet_ids
}

output "dhcp_options_set_id" {
  description = "The ID of the DHCP options set"
  value       = module.networking.dhcp_options_set_id
}

output "internet_service_id" {
  description = "The ID of the Internet Service"
  value       = module.networking.internet_service_id
}

output "nat_service_ids" {
  description = "Map of NAT service key to NAT service ID"
  value       = module.networking.nat_service_ids
}

output "public_ip_ids" {
  description = "Map of public IP key to public IP allocation ID"
  value       = module.networking.public_ip_ids
}

output "public_ips" {
  description = "Map of public IP key to public IP address"
  value       = module.networking.public_ips
}

output "net_peering_ids" {
  description = "Map of peering key to Net peering ID"
  value       = module.networking.net_peering_ids
}

output "net_access_point_ids" {
  description = "Map of access point key to Net access point ID"
  value       = module.networking.net_access_point_ids
}

output "route_table_ids" {
  description = "Map of route table key to route table ID"
  value       = module.networking.route_table_ids
}

output "load_balancer_dns_names" {
  description = "Map of load balancer key to DNS name"
  value       = module.networking.load_balancer_dns_names
}

output "nic_ids" {
  description = "Map of NIC key to NIC ID"
  value       = module.networking.nic_ids
}
