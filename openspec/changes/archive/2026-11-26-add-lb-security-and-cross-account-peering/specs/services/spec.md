## ADDED Requirements

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
