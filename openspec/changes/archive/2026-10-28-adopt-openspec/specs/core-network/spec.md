## ADDED Requirements

### Requirement: Net
The module SHALL create exactly one Net with `ip_range` and `tenancy` (default `default`). The Net SHALL carry the common tags and, when `name` is set (default `null`), the tag `Name` with that value.

#### Scenario: Net with a name
- **WHEN** `ip_range = "10.0.0.0/16"` and `name = "my-network"`
- **THEN** the plan contains one Net with that range, tenancy `default` and the tag `Name = "my-network"`

#### Scenario: Net without a name
- **WHEN** `name` is not set
- **THEN** the Net carries no `Name` tag

### Requirement: Net CIDR validation
`ip_range` SHALL be a valid CIDR block.

#### Scenario: Rejected CIDR
- **WHEN** `ip_range = "not-a-cidr"`
- **THEN** the plan fails with "The ip_range must be a valid CIDR block (e.g., '10.0.0.0/16')."

### Requirement: Tenancy validation
`tenancy` SHALL be `default` or `dedicated`.

#### Scenario: Dedicated tenancy
- **WHEN** `tenancy = "dedicated"`
- **THEN** the Net is planned with dedicated tenancy

#### Scenario: Rejected tenancy
- **WHEN** `tenancy = "shared"`
- **THEN** the plan fails with "Tenancy must be 'default' or 'dedicated'."

### Requirement: Subnets
The module SHALL create one subnet in the Net for every entry of `subnets`, with the entry's `ip_range` and `subregion_name`, addressed by the entry's key. Each subnet SHALL carry the common tags and `Name` equal to its key.

#### Scenario: Two subnets
- **WHEN** `subnets` has the keys `public_a` (`10.0.1.0/24`, `eu-west-2a`) and `public_b` (`10.0.2.0/24`, `eu-west-2b`)
- **THEN** the plan contains two subnets with those ranges and subregions, tagged `Name = "public_a"` and `Name = "public_b"`

### Requirement: At least one subnet
`subnets` SHALL contain at least one entry.

#### Scenario: Rejected empty subnets
- **WHEN** `subnets = {}`
- **THEN** the plan fails with "At least one subnet must be defined."

### Requirement: Optional DHCP options
The module SHALL create one DHCP options set, tagged with the common tags, and set it on the Net when at least one of `dhcp_domain_name`, `dhcp_domain_name_servers`, `dhcp_ntp_servers` or `dhcp_log_servers` is not `null` (all default `null`), and neither otherwise. The set SHALL use the values of those four inputs.

#### Scenario: DHCP disabled
- **WHEN** none of the four DHCP inputs is set
- **THEN** the plan contains no DHCP options set and `dhcp_options_set_id` is `null`

#### Scenario: DHCP enabled by a domain name
- **WHEN** `dhcp_domain_name = "example.com"` and `dhcp_domain_name_servers = ["10.0.0.2"]`
- **THEN** the plan contains one DHCP options set with those values and its attachment to the Net

#### Scenario: DHCP enabled by NTP servers only
- **WHEN** only `dhcp_ntp_servers = ["10.0.0.3"]` is set
- **THEN** the plan contains one DHCP options set and its attachment to the Net
