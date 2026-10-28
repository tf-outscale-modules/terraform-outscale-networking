## ADDED Requirements

### Requirement: Optional Internet Service
The module SHALL create one Internet Service, tagged with the common tags, and attach it to the Net only when `enable_internet_service` is true (default `false`).

#### Scenario: Disabled by default
- **WHEN** `enable_internet_service` is not set
- **THEN** the plan contains no Internet Service and `internet_service_id` is `null`

#### Scenario: Enabled
- **WHEN** `enable_internet_service = true`
- **THEN** the plan contains one Internet Service and its link to the Net

### Requirement: Optional NAT services
The module SHALL create, for every entry of `nat_services`, a NAT service in the subnet named by the entry's `subnet_key`, tagged with `Name` equal to the entry's key, only when `enable_nat_services` is true (default `false`). NAT services SHALL be created after the Internet Service link.

#### Scenario: Disabled by default
- **WHEN** `nat_services` is declared and `enable_nat_services` is not set
- **THEN** the plan contains no NAT service and `nat_service_ids` is empty

#### Scenario: Enabled
- **WHEN** `enable_nat_services = true` and `nat_services = { egress = { subnet_key = "public_a" } }`
- **THEN** the plan contains one NAT service `egress` in the subnet `public_a`

### Requirement: Public IP per NAT service
Every NAT service SHALL get its own public IP, created by the module and tagged with the common tags and `Name = "<key>-nat"`. These public IPs SHALL NOT appear in `public_ip_ids` or `public_ips`.

#### Scenario: NAT public IP
- **WHEN** `enable_nat_services = true` and `nat_services` has the key `egress`
- **THEN** the plan contains one public IP tagged `Name = "egress-nat"` used by the NAT service, and `public_ips` stays empty

### Requirement: Standalone public IPs
The module SHALL create one public IP for every entry of `public_ips` (default `{}`), without any enable flag, tagged with the common tags, the entry's `tags` (default `{}`) and `Name` equal to the entry's key. `public_ip_ids` and `public_ips` SHALL expose these public IPs only.

#### Scenario: Standalone public IP
- **WHEN** `public_ips = { bastion = { tags = { Role = "bastion" } } }`
- **THEN** the plan contains one public IP tagged `Name = "bastion"` and `Role = "bastion"`, and `public_ip_ids` has the key `bastion`

#### Scenario: No standalone public IP
- **WHEN** `public_ips` is not set
- **THEN** the plan contains no standalone public IP
