## MODIFIED Requirements

### Requirement: Routes through the Internet Service or a gateway
A route with `use_internet_service = true` SHALL target the Internet Service created by the module and requires `enable_internet_service = true`; a route with `gateway_id` set SHALL target that gateway. The route SHALL use the entry's `destination_ip_range`.

#### Scenario: Default route through the Internet Service
- **WHEN** `enable_internet_service = true` and a route of table `public` sets `destination_ip_range = "0.0.0.0/0"` and `use_internet_service = true`
- **THEN** the plan contains one route in `public` to `0.0.0.0/0` through the module's Internet Service

#### Scenario: Route through an external gateway
- **WHEN** a route sets `gateway_id = "vgw-12345678"`
- **THEN** the plan contains one route to that gateway

#### Scenario: Internet Service route without the Internet Service
- **WHEN** a route sets `use_internet_service = true` and `enable_internet_service` is false
- **THEN** the plan fails with "A route with use_internet_service = true requires enable_internet_service = true."

## ADDED Requirements

### Requirement: One target per route
A route SHALL set at most one target among `use_internet_service`/`gateway_id`, `nat_key`, `peering_key` and `nic_key`. A route with several targets SHALL be rejected, and a route with no target SHALL create nothing and raise a warning.

#### Scenario: Several targets
- **WHEN** a route sets both `nat_key = "egress"` and `nic_key = "appliance"`
- **THEN** the plan fails with "Each route must set at most one target: use_internet_service or gateway_id, nat_key, peering_key, or nic_key."

#### Scenario: No target
- **WHEN** a route sets only `destination_ip_range`
- **THEN** the plan succeeds, contains no route for it and warns that the route has no target
