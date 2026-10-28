## MODIFIED Requirements

### Requirement: Optional NAT services
The module SHALL create, for every entry of `nat_services`, a NAT service in the subnet named by the entry's `subnet_key`, tagged with `Name` equal to the entry's key, only when `enable_nat_services` is true (default `false`). NAT services SHALL be created after the Internet Service link. The module SHALL warn when `enable_nat_services` is true and `enable_internet_service` is false, without blocking the plan.

#### Scenario: Disabled by default
- **WHEN** `nat_services` is declared and `enable_nat_services` is not set
- **THEN** the plan contains no NAT service and `nat_service_ids` is empty

#### Scenario: Enabled
- **WHEN** `enable_nat_services = true` and `nat_services = { egress = { subnet_key = "public_a" } }`
- **THEN** the plan contains one NAT service `egress` in the subnet `public_a`

#### Scenario: NAT service without the Internet Service
- **WHEN** `enable_nat_services = true` and `enable_internet_service` is false
- **THEN** the plan succeeds and warns that NAT services need an Internet Service attached to the Net
