# Outscale Provider Resource References

Provider: `outscale/outscale` ~> 1.0 (latest: 1.3.2)
Registry: https://registry.terraform.io/providers/outscale/outscale/latest

## Resources Used

### Core
- `outscale_net` — Virtual network (VPC equivalent)
- `outscale_subnet` — Subnet within a Net
- `outscale_dhcp_option` — DHCP options set
- `outscale_net_attributes` — Associates DHCP options with a Net

### Connectivity
- `outscale_internet_service` — Internet gateway
- `outscale_internet_service_link` — Links internet service to a Net
- `outscale_public_ip` — Elastic IP address
- `outscale_nat_service` — NAT gateway
- `outscale_net_peering` — VPC peering connection
- `outscale_net_peering_acceptation` — Accept a peering request
- `outscale_net_access_point` — VPC endpoint

### Routing
- `outscale_route_table` — Route table
- `outscale_route_table_link` — Associates route table with subnet
- `outscale_route` — Individual route entry

### Services
- `outscale_load_balancer` — Load balancer
- `outscale_nic` — Network interface card

## Resources NOT Used (Out of Scope)
- `outscale_vpn_*` — VPN resources
- `outscale_virtual_gateway*` — Virtual gateway resources
- `outscale_client_gateway` — Client gateway
- `outscale_security_group*` — Security group resources (separate module)
- `outscale_load_balancer_attributes` — LB attributes (follow-up)
- `outscale_load_balancer_listener_rule` — LB listener rules (follow-up)
- `outscale_load_balancer_policy` — LB policies (follow-up)
- `outscale_load_balancer_vms` — LB VM attachments (follow-up)
- `outscale_nic_link` — NIC attachment (follow-up)
- `outscale_nic_private_ip` — NIC private IP management (follow-up)
