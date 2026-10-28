## ADDED Requirements

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
