# services Specification

## Purpose
Optional load balancers with listeners and NICs placed in the module subnets.

## Requirements

### Requirement: Optional load balancers
The module SHALL create one load balancer for every entry of `load_balancers` (default `{}`) only when `enable_load_balancers` is true (default `false`). A load balancer SHALL use the entry's `load_balancer_name`, `load_balancer_type` (default `internet-facing`) and the subnets named by `subnet_keys` (default `[]`), and SHALL carry the common tags, the entry's `tags` (default `{}`) and `Name` equal to the entry's key. `load_balancer_dns_names` SHALL map each key to the DNS name.

#### Scenario: Disabled by default
- **WHEN** `load_balancers` is declared and `enable_load_balancers` is not set
- **THEN** the plan contains no load balancer and `load_balancer_dns_names` is empty

#### Scenario: Enabled with defaults
- **WHEN** `enable_load_balancers = true` and an entry `web` sets `load_balancer_name = "web-lb"`, `subnet_keys = ["public_a"]` and one listener
- **THEN** the plan contains one internet-facing load balancer `web-lb` in the subnet `public_a`, tagged `Name = "web"`

#### Scenario: Internal load balancer
- **WHEN** an entry sets `load_balancer_type = "internal"`
- **THEN** the load balancer is planned with the type `internal`

### Requirement: Load balancer listeners and security groups
A load balancer SHALL get one listener per element of the entry's `listeners` with its `backend_port`, `backend_protocol`, `load_balancer_port`, `load_balancer_protocol` and optional `server_certificate_id`. It SHALL be attached to the security groups of `security_group_ids` (default `[]`), passed in by id, and to none when the list is empty.

#### Scenario: HTTPS listener
- **WHEN** an entry declares a listener with `load_balancer_port = 443`, `load_balancer_protocol = "HTTPS"`, `backend_port = 8080`, `backend_protocol = "HTTP"` and a `server_certificate_id`
- **THEN** the load balancer is planned with that one listener

#### Scenario: Security groups by id
- **WHEN** an entry sets `security_group_ids = ["sg-12345678"]`
- **THEN** the load balancer is attached to `sg-12345678`

### Requirement: NICs
The module SHALL create one NIC in the subnet named by `subnet_key` for every entry of `nics` (default `{}`), without any enable flag, with the entry's `description`, one `private_ips` block per element (`private_ip`, `is_primary`), and the security groups of `security_group_ids` (default `[]`, none when empty). A NIC SHALL carry the common tags and `Name` equal to the entry's key. `nic_ids` SHALL map each key to the NIC id.

#### Scenario: No NICs
- **WHEN** `nics` is not set
- **THEN** the plan contains no NIC and `nic_ids` is empty

#### Scenario: NIC with a fixed private IP
- **WHEN** `nics = { appliance = { subnet_key = "public_a", private_ips = [{ private_ip = "10.0.1.10", is_primary = true }] } }`
- **THEN** the plan contains one NIC `appliance` in the subnet `public_a` with the primary private IP `10.0.1.10`

### Requirement: Load balancer secure cookies and fixed public IP
A load balancer entry SHALL accept `secured_cookies` (`bool`, default `null`) and `public_ip_key` (`string`, default `null`). A `null` value SHALL NOT be sent. A set `secured_cookies` SHALL be planned as given; a set `public_ip_key` SHALL give the load balancer the public IP created from the `public_ips` entry of that key.

#### Scenario: Defaults send nothing
- **WHEN** an entry sets neither `secured_cookies` nor `public_ip_key`
- **THEN** the plan is unchanged from before this option and a second plan after apply is empty

#### Scenario: Secure cookies
- **WHEN** an entry sets `secured_cookies = true`
- **THEN** the load balancer is planned with `secured_cookies = true`

#### Scenario: Fixed public IP
- **WHEN** `public_ips = { lb = {} }` is declared and an internet-facing entry sets `public_ip_key = "lb"`
- **THEN** the load balancer is planned with the address of the public IP `lb`

### Requirement: Public IP key validation
`public_ip_key` SHALL be accepted only on a load balancer whose `load_balancer_type` is `internet-facing` and SHALL name a key of `public_ips`; otherwise the input SHALL be rejected with a validation error.

#### Scenario: Public IP on an internal load balancer
- **WHEN** an entry sets `load_balancer_type = "internal"` and `public_ip_key = "lb"`
- **THEN** validation fails with a message that a public IP needs an internet-facing load balancer

#### Scenario: Unknown public IP key
- **WHEN** an entry sets `public_ip_key = "missing"` and `public_ips` has no key `missing`
- **THEN** validation fails with a message naming the keys of `public_ips`

### Requirement: Load balancer Subregion placement
A load balancer entry SHALL accept `subregion_names` (`list(string)`, default `null`) for a load balancer outside a Net. When `null` the argument SHALL NOT be sent. `subregion_names` and a non-empty `subnet_keys` SHALL NOT be set together; the input SHALL be rejected with a validation error. When `subnet_keys` is empty the module SHALL send no `subnets` argument. Changing `subregion_names` of an existing load balancer replaces it.

#### Scenario: Subregion load balancer
- **WHEN** an entry sets `subnet_keys = []` and `subregion_names = ["eu-west-2a"]`
- **THEN** the load balancer is planned with that Subregion and no Subnet

#### Scenario: Subnets and Subregions together
- **WHEN** an entry sets `subnet_keys = ["public_a"]` and `subregion_names = ["eu-west-2a"]`
- **THEN** validation fails with a message that `subnet_keys` and `subregion_names` are mutually exclusive

#### Scenario: Subnet load balancer unchanged
- **WHEN** an entry sets `subnet_keys = ["public_a"]` and no `subregion_names`
- **THEN** the load balancer is planned in the Subnet `public_a` exactly as before
