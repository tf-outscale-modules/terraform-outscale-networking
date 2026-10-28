## ADDED Requirements

### Requirement: Route tables
The module SHALL create one route table in the Net for every entry of `route_tables` (default `{}`), without any enable flag, tagged with the common tags and `Name` equal to the entry's key. `route_table_ids` SHALL map each key to the route table id.

#### Scenario: No route tables
- **WHEN** `route_tables` is not set
- **THEN** the plan contains no route table and `route_table_ids` is empty

#### Scenario: Route tables created
- **WHEN** `route_tables` has the keys `public` and `private`
- **THEN** the plan contains two route tables and `route_table_ids` has both keys

### Requirement: Subnet associations
The module SHALL associate each route table with every subnet named in its `subnet_keys` (default `[]`), one association per pair.

#### Scenario: Two subnets on one table
- **WHEN** route table `public` sets `subnet_keys = ["public_a", "public_b"]`
- **THEN** the plan contains two associations, one for each subnet, with the route table `public`

### Requirement: Main route table
The module SHALL make the route table named by `main_route_table_key` (default `null`) the main route table of the Net, and SHALL change the main route table of no Net otherwise.

#### Scenario: Main route table set
- **WHEN** `main_route_table_key = "private"` and the route table `private` is declared
- **THEN** the plan contains one main route table link to `private`

#### Scenario: No main route table
- **WHEN** `main_route_table_key` is not set
- **THEN** the plan contains no main route table link

### Requirement: Routes through the Internet Service or a gateway
A route with `use_internet_service = true` SHALL target the Internet Service created by the module; a route with `gateway_id` set SHALL target that gateway. The route SHALL use the entry's `destination_ip_range`.

#### Scenario: Default route through the Internet Service
- **WHEN** `enable_internet_service = true` and a route of table `public` sets `destination_ip_range = "0.0.0.0/0"` and `use_internet_service = true`
- **THEN** the plan contains one route in `public` to `0.0.0.0/0` through the module's Internet Service

#### Scenario: Route through an external gateway
- **WHEN** a route sets `gateway_id = "vgw-12345678"`
- **THEN** the plan contains one route to that gateway

### Requirement: Routes through a NAT service, a peering or a NIC
A route with `nat_key` set SHALL target the NAT service of that key, with `peering_key` the peering of that key and with `nic_key` the NIC of that key.

#### Scenario: Route through a NAT service
- **WHEN** NAT service `egress` is enabled and a route of table `private` sets `destination_ip_range = "0.0.0.0/0"` and `nat_key = "egress"`
- **THEN** the plan contains one route in `private` through the NAT service `egress`

#### Scenario: Route through a peering
- **WHEN** peering `shared` is enabled and a route sets `destination_ip_range = "10.1.0.0/16"` and `peering_key = "shared"`
- **THEN** the plan contains one route to that range through the peering `shared`

#### Scenario: Route through a NIC
- **WHEN** NIC `appliance` is declared and a route sets `destination_ip_range = "10.2.0.0/16"` and `nic_key = "appliance"`
- **THEN** the plan contains one route to that range through the NIC `appliance`
