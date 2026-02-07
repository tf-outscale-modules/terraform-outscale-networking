output "net_id" {
  description = "The ID of the Net"
  value       = module.networking.net_id
}

output "subnet_ids" {
  description = "Map of subnet key to subnet ID"
  value       = module.networking.subnet_ids
}

output "internet_service_id" {
  description = "The ID of the Internet Service"
  value       = module.networking.internet_service_id
}

output "route_table_ids" {
  description = "Map of route table key to route table ID"
  value       = module.networking.route_table_ids
}
