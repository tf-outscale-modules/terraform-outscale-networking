# Outscale Networking Module — Shaping Notes

## Scope

Terraform module for managing Outscale networking resources. Covers 10 resource categories across ~20 Outscale resource types.

### In Scope

- Net (VPC equivalent)
- Subnets
- DHCP Options
- Internet Service (Internet Gateway)
- NAT Services
- Public IPs (Elastic IPs)
- Net Peerings (VPC Peering)
- Net Access Points (VPC Endpoints)
- Route Tables and Routes
- Load Balancers (basic creation)
- NICs (Network Interface Cards)

### Out of Scope

- VPN Gateway / VPN Connections
- Direct Link (Direct Connect equivalent)
- Security Groups (separate module)
- Load Balancer sub-resources (attributes, listener rules, policies, VM attachments)
- NIC sub-resources (link, private IP management)

## Key Decisions

1. **Single Net per module instance** — The module creates exactly one Net. Multiple Nets require multiple module calls.
2. **Subnets always created** — `ip_range` and `subnets` are required variables.
3. **Feature flags** — Optional features use `enable_*` booleans to control resource creation.
4. **Key-based references** — Resources reference each other by map keys (e.g., `subnet_key` in NAT service points to a key in the `subnets` map).
5. **Auto-created Public IPs for NAT** — Each NAT service gets its own auto-created Public IP. Standalone Public IPs are separate.
6. **Provider version** — `~> 1.0` allows 1.x but not 2.0.
7. **Terraform version** — `>= 1.10` for OpenTofu 1.11 compatibility.

## Context

- Provider: `outscale/outscale` (Terraform Registry)
- Cloud: 3DS Outscale (French cloud provider, AWS-compatible API)
- Region: Primarily `eu-west-2`
