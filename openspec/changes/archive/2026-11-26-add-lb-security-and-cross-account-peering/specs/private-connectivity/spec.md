## ADDED Requirements

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
