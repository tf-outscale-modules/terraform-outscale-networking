# Complete Example

Full-featured deployment demonstrating all module capabilities.

## Usage

```bash
tofu init
tofu plan
tofu apply
```

## What This Creates

- 1 Net (`10.0.0.0/16`) with DHCP options (custom DNS, NTP)
- 4 Subnets: 2 public + 2 private across two subregions
- 1 Internet Service
- 1 NAT Service with auto-created Public IP
- 1 Standalone Public IP (bastion)
- 1 Net Peering with auto-accept
- 1 Net Access Point for Outscale API
- 2 Route Tables: public (IGW default route) and private (NAT default route)
- 1 Load Balancer (internet-facing, HTTP on port 80)
- 1 NIC with a static private IP
