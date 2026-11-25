# private-connectivity Specification

## Purpose
Optional Net peerings with auto-acceptance and Net access points to Outscale services.

## Requirements

### Requirement: Optional Net peerings
The module SHALL create, for every entry of `net_peerings`, a peering from the module's Net to the entry's `accepter_net_id` (and `accepter_owner_id` when set), tagged with the common tags and `Name` equal to the entry's key, only when `enable_net_peerings` is true (default `false`).

#### Scenario: Disabled by default
- **WHEN** `net_peerings` is declared and `enable_net_peerings` is not set
- **THEN** the plan contains no peering and `net_peering_ids` is empty

#### Scenario: Enabled
- **WHEN** `enable_net_peerings = true` and `net_peerings = { shared = { accepter_net_id = "vpc-12345678" } }`
- **THEN** the plan contains one peering `shared` from the module's Net to `vpc-12345678`

#### Scenario: Cross-account peering
- **WHEN** an entry sets `accepter_owner_id = "123456789012"`
- **THEN** the peering is planned with that accepter owner

### Requirement: Peering auto-acceptance
The module SHALL accept a peering only when its entry sets `auto_accept = true` (default `false`) and `enable_net_peerings` is true.

#### Scenario: Auto-accept
- **WHEN** `enable_net_peerings = true` and an entry sets `auto_accept = true`
- **THEN** the plan contains one acceptation for that peering

#### Scenario: No auto-accept by default
- **WHEN** an entry omits `auto_accept`
- **THEN** the plan contains no acceptation for that peering

### Requirement: Optional Net access points
The module SHALL create, for every entry of `net_access_points`, an access point in the Net for the entry's `service_name`, tagged with the common tags and `Name` equal to the entry's key, only when `enable_net_access_points` is true (default `false`). The access point SHALL be associated with the route tables named by the entry's `route_table_keys` (default `[]`).

#### Scenario: Disabled by default
- **WHEN** `net_access_points` is declared and `enable_net_access_points` is not set
- **THEN** the plan contains no access point and `net_access_point_ids` is empty

#### Scenario: Enabled with route tables
- **WHEN** `enable_net_access_points = true`, route table `private` is declared and an entry sets `service_name = "com.outscale.eu-west-2.api"` and `route_table_keys = ["private"]`
- **THEN** the plan contains one access point for that service associated with the route table `private`

#### Scenario: Enabled without route tables
- **WHEN** an entry omits `route_table_keys`
- **THEN** the access point is planned with no route table

### Requirement: Cross-account peering source account
A peering entry SHALL accept `source_net_account_id` (`string`, default `null`), the account that owns the module's Net, for a cross-account peering together with `accepter_owner_id`. A `null` value SHALL NOT be sent. When set it SHALL be a 12-digit account id; any other value SHALL be rejected with a validation error. Changing it on an existing peering replaces the peering.

#### Scenario: Default sends nothing
- **WHEN** a peering entry omits `source_net_account_id`
- **THEN** the plan is unchanged from before this option and a second plan after apply is empty

#### Scenario: Cross-account peering with both accounts
- **WHEN** `enable_net_peerings = true` and an entry sets `accepter_net_id = "vpc-12345678"`, `accepter_owner_id = "210987654321"` and `source_net_account_id = "123456789012"`
- **THEN** the plan contains one peering with those source and accepter accounts and no acceptation

#### Scenario: Malformed source account
- **WHEN** an entry sets `source_net_account_id = "not-an-account"`
- **THEN** validation fails with a message that the account id has 12 digits

### Requirement: Accepter side outside the module
The module SHALL NOT accept or manage the accepter side of a peering in another account: that account accepts it, and `auto_accept` applies only to a peering whose accepter is in the same account. The `net_peerings` description SHALL state this limit.

#### Scenario: Cross-account peering is not auto-accepted for the other account
- **WHEN** an entry has `accepter_owner_id` of another account
- **THEN** the module documents that the accepter account must accept the peering itself
