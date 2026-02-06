# Outscale Networking Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Outscale Provider][provider-badge]][provider-url]
[![Latest Release][release-badge]][release-url]

Terraform module for managing Outscale networking resources — Nets, Subnets, Internet Services, NAT Services, Peerings, Access Points, Route Tables, Load Balancers, and NICs.

## Features

- **Net (VPC)** — Single virtual network with configurable CIDR and tenancy
- **Subnets** — Multiple subnets across subregions via a simple map
- **DHCP Options** — Custom DNS, NTP, and log servers
- **Internet Service** — Internet gateway with automatic Net attachment
- **NAT Services** — NAT gateways with auto-created Public IPs
- **Public IPs** — Standalone elastic IP addresses
- **Net Peerings** — VPC peering with optional auto-accept
- **Net Access Points** — VPC endpoints for Outscale services
- **Route Tables** — Custom routing with subnet associations and a main route table option
- **Load Balancers** — Internet-facing or internal load balancers
- **NICs** — Network interface cards with private IP management

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| outscale | ~> 1.0 |

## Usage

### Basic Example

Net with two public subnets, an Internet Service, and a route table:

```hcl
module "networking" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/outscale-network.git?ref=v0.1.0"

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

  enable_internet_service = true

  route_tables = {
    public = {
      subnet_keys = ["public_a", "public_b"]
      routes = [
        {
          destination_ip_range = "0.0.0.0/0"
          gateway_id           = "igw-ref"
        }
      ]
    }
  }

  tags = {
    Project     = "my-project"
    Environment = "dev"
  }
}
```

### Complete Example

See [`examples/complete/`](examples/complete/) for a full example with all features enabled.

### Conditional Creation

All connectivity and service resources are controlled by `enable_*` flags:

```hcl
module "networking" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/outscale-network.git?ref=v0.1.0"

  ip_range = "10.0.0.0/16"
  subnets = {
    main = {
      ip_range       = "10.0.1.0/24"
      subregion_name = "eu-west-2a"
    }
  }

  # These default to false — no extra resources created
  enable_internet_service  = false
  enable_nat_services      = false
  enable_net_peerings      = false
  enable_net_access_points = false
  enable_load_balancers    = false
}
```

## Security Considerations

1. No secrets are stored in module code — credentials must be provided via environment variables or a vault
2. Public IPs and Internet Services are disabled by default — explicit opt-in required
3. Security group IDs for load balancers and NICs are passed by reference, not created by this module
4. State files may contain sensitive data — use encrypted remote backends

## Known Limitations

1. Load balancer sub-resources (attributes, listener rules, policies, VM attachments) are not managed — use separate resources
2. NIC sub-resources (link, private IP management) are not managed — use separate resources
3. VPN and Direct Link resources are out of scope
4. Net peering auto-accept only works for same-account peerings
5. Security groups are not created by this module — pass existing IDs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Documentation

| Document | Description |
|----------|-------------|
| [README](README.md) | This file |
| [CHANGELOG](CHANGELOG.md) | Version history |
| [LICENSE](LICENSE) | Apache 2.0 license |

## Contributing

1. Fork the repository
2. Create a feature branch from `develop`
3. Run `pre-commit install` to set up git hooks
4. Make your changes and ensure all checks pass: `pre-commit run -a`
5. Submit a merge request

## License

Licensed under the [Apache License 2.0](LICENSE).

## Disclaimer

This module is provided "as is", without warranty of any kind, express or implied. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[provider-badge]: https://img.shields.io/badge/Outscale%20Provider-~%3E1.0-blue
[provider-url]: https://registry.terraform.io/providers/outscale/outscale/latest

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/outscale-network?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/outscale-network/-/releases
