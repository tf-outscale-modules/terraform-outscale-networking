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
          use_internet_service = true
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
2. Outscale supports only one subnet per load balancer — create multiple LBs for multi-AZ
3. NIC sub-resources (link, private IP management) are not managed — use separate resources
4. VPN and Direct Link resources are out of scope
5. Net peering auto-accept only works for same-account peerings; cross-account requires `accepter_owner_id`
6. Security groups are not created by this module — pass existing IDs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_outscale"></a> [outscale](#requirement\_outscale) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_outscale"></a> [outscale](#provider\_outscale) | ~> 1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [outscale_dhcp_option.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/dhcp_option) | resource |
| [outscale_internet_service.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/internet_service) | resource |
| [outscale_internet_service_link.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/internet_service_link) | resource |
| [outscale_load_balancer.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/load_balancer) | resource |
| [outscale_main_route_table_link.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/main_route_table_link) | resource |
| [outscale_nat_service.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/nat_service) | resource |
| [outscale_net.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/net) | resource |
| [outscale_net_access_point.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/net_access_point) | resource |
| [outscale_net_attributes.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/net_attributes) | resource |
| [outscale_net_peering.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/net_peering) | resource |
| [outscale_net_peering_acceptation.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/net_peering_acceptation) | resource |
| [outscale_nic.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/nic) | resource |
| [outscale_public_ip.nat](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/public_ip) | resource |
| [outscale_public_ip.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/public_ip) | resource |
| [outscale_route.gateway](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route) | resource |
| [outscale_route.nat](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route) | resource |
| [outscale_route.nic](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route) | resource |
| [outscale_route.peering](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route) | resource |
| [outscale_route_table.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route_table) | resource |
| [outscale_route_table_link.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/route_table_link) | resource |
| [outscale_subnet.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dhcp_domain_name"></a> [dhcp\_domain\_name](#input\_dhcp\_domain\_name) | The domain name for the DHCP options set (e.g., 'example.com') | `string` | `null` | no |
| <a name="input_dhcp_domain_name_servers"></a> [dhcp\_domain\_name\_servers](#input\_dhcp\_domain\_name\_servers) | List of DNS server IPs for the DHCP options set | `list(string)` | `null` | no |
| <a name="input_dhcp_log_servers"></a> [dhcp\_log\_servers](#input\_dhcp\_log\_servers) | List of log server IPs for the DHCP options set | `list(string)` | `null` | no |
| <a name="input_dhcp_ntp_servers"></a> [dhcp\_ntp\_servers](#input\_dhcp\_ntp\_servers) | List of NTP server IPs for the DHCP options set | `list(string)` | `null` | no |
| <a name="input_enable_internet_service"></a> [enable\_internet\_service](#input\_enable\_internet\_service) | Whether to create an Internet Service and attach it to the Net | `bool` | `false` | no |
| <a name="input_enable_load_balancers"></a> [enable\_load\_balancers](#input\_enable\_load\_balancers) | Whether to create load balancers | `bool` | `false` | no |
| <a name="input_enable_nat_services"></a> [enable\_nat\_services](#input\_enable\_nat\_services) | Whether to create NAT services (requires enable\_internet\_service = true) | `bool` | `false` | no |
| <a name="input_enable_net_access_points"></a> [enable\_net\_access\_points](#input\_enable\_net\_access\_points) | Whether to create Net access points (VPC endpoints) | `bool` | `false` | no |
| <a name="input_enable_net_peerings"></a> [enable\_net\_peerings](#input\_enable\_net\_peerings) | Whether to create Net peering connections | `bool` | `false` | no |
| <a name="input_ip_range"></a> [ip\_range](#input\_ip\_range) | The IP range for the Net, in CIDR notation (e.g., '10.0.0.0/16') | `string` | n/a | yes |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | Map of load balancer definitions | <pre>map(object({<br/>    load_balancer_name = string<br/>    load_balancer_type = optional(string, "internet-facing")<br/>    subnet_keys        = optional(list(string), [])<br/>    security_group_ids = optional(list(string), [])<br/>    listeners = list(object({<br/>      backend_port           = number<br/>      backend_protocol       = string<br/>      load_balancer_port     = number<br/>      load_balancer_protocol = string<br/>      server_certificate_id  = optional(string)<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_main_route_table_key"></a> [main\_route\_table\_key](#input\_main\_route\_table\_key) | Key from route\_tables to set as the main route table for the Net | `string` | `null` | no |
| <a name="input_nat_services"></a> [nat\_services](#input\_nat\_services) | Map of NAT service definitions. Each key is a logical name, subnet\_key references a key in the subnets variable. A Public IP is auto-created for each NAT service. | <pre>map(object({<br/>    subnet_key = string<br/>  }))</pre> | `{}` | no |
| <a name="input_net_access_points"></a> [net\_access\_points](#input\_net\_access\_points) | Map of Net access point definitions. service\_name is the Outscale service name (e.g., 'com.outscale.eu-west-2.api'). route\_table\_keys reference keys in the route\_tables variable. | <pre>map(object({<br/>    service_name     = string<br/>    route_table_keys = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_net_peerings"></a> [net\_peerings](#input\_net\_peerings) | Map of Net peering definitions. accepter\_net\_id is the ID of the remote Net. accepter\_owner\_id is required for cross-account peerings. Set auto\_accept to true to automatically accept the peering (only works for same-account peerings). | <pre>map(object({<br/>    accepter_net_id  = string<br/>    accepter_owner_id = optional(string)<br/>    auto_accept      = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_nics"></a> [nics](#input\_nics) | Map of Network Interface Card (NIC) definitions | <pre>map(object({<br/>    subnet_key         = string<br/>    description        = optional(string)<br/>    security_group_ids = optional(list(string), [])<br/>    private_ips = optional(list(object({<br/>      private_ip = string<br/>      is_primary = bool<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_public_ips"></a> [public\_ips](#input\_public\_ips) | Map of standalone Public IP (Elastic IP) definitions | <pre>map(object({<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | Map of route table definitions. subnet\_keys reference keys in the subnets variable. routes define individual route entries with a destination and one target. Set use\_internet\_service to true to route via the module's Internet Service, or pass a gateway\_id for external gateways. | <pre>map(object({<br/>    subnet_keys = optional(list(string), [])<br/>    routes = optional(list(object({<br/>      destination_ip_range = string<br/>      use_internet_service = optional(bool, false)<br/>      gateway_id           = optional(string)<br/>      nat_key              = optional(string)<br/>      peering_key          = optional(string)<br/>      nic_key              = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnet definitions. Each key is a logical name, each value defines the subnet's CIDR and subregion. | <pre>map(object({<br/>    ip_range       = string<br/>    subregion_name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources that support tagging | `map(string)` | `{}` | no |
| <a name="input_tenancy"></a> [tenancy](#input\_tenancy) | The tenancy of VMs launched in the Net ('default' or 'dedicated') | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dhcp_options_set_id"></a> [dhcp\_options\_set\_id](#output\_dhcp\_options\_set\_id) | The ID of the DHCP options set (if created) |
| <a name="output_internet_service_id"></a> [internet\_service\_id](#output\_internet\_service\_id) | The ID of the Internet Service (if created) |
| <a name="output_load_balancer_dns_names"></a> [load\_balancer\_dns\_names](#output\_load\_balancer\_dns\_names) | Map of load balancer key to DNS name |
| <a name="output_nat_service_ids"></a> [nat\_service\_ids](#output\_nat\_service\_ids) | Map of NAT service key to NAT service ID |
| <a name="output_net_access_point_ids"></a> [net\_access\_point\_ids](#output\_net\_access\_point\_ids) | Map of access point key to Net access point ID |
| <a name="output_net_id"></a> [net\_id](#output\_net\_id) | The ID of the Net |
| <a name="output_net_peering_ids"></a> [net\_peering\_ids](#output\_net\_peering\_ids) | Map of peering key to Net peering ID |
| <a name="output_nic_ids"></a> [nic\_ids](#output\_nic\_ids) | Map of NIC key to NIC ID |
| <a name="output_public_ip_ids"></a> [public\_ip\_ids](#output\_public\_ip\_ids) | Map of public IP key to public IP allocation ID (standalone public IPs only) |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of public IP key to public IP address (standalone public IPs only) |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | Map of route table key to route table ID |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet key to subnet ID |
<!-- END_TF_DOCS -->

## Documentation

| Document | Description |
|----------|-------------|
| [README](README.md) | This file |
| [SECURITY](SECURITY.md) | Security considerations and practices |
| [TESTING](TESTING.md) | Testing guide and test structure |
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
