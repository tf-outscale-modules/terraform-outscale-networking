# module-contract Specification

## Purpose
Cross-cutting contract of the module: supported tooling and provider, required inputs, common tags and outputs.

## Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.10"` and SHALL pin `outscale/outscale` with `~> 1.8` in `versions.tf`. It SHALL work on OpenTofu and Terraform.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the outscale provider resolves to a 1.x release at or above 1.8

#### Scenario: Version below the floor
- **WHEN** the module is initialised with OpenTofu or Terraform 1.9
- **THEN** initialisation fails on the `required_version` constraint

### Requirement: No provider or backend configuration
The module SHALL NOT contain `provider {}` or `backend {}` blocks; the caller configures the Outscale provider (credentials, region) and the state backend.

#### Scenario: Provider block inside the module
- **WHEN** a change adds a `provider "outscale" {}` or `backend` block to a module file
- **THEN** it is moved to the caller or to the example's own configuration, and the module only declares `required_providers`

### Requirement: Required inputs
The module SHALL require `ip_range` and `subnets`; every other input SHALL be optional with a default. Optional features SHALL be off by default.

#### Scenario: Minimal call
- **WHEN** the module is called with only `ip_range = "10.0.0.0/16"` and one subnet
- **THEN** the plan contains the Net and the subnet and nothing else

#### Scenario: Missing required input
- **WHEN** the module is called without `ip_range` or without `subnets`
- **THEN** the plan fails because the input is required

### Requirement: Common tags
Every resource that supports tags SHALL carry `ManagedBy = "terraform"` merged with the `tags` input (default `{}`). A `ManagedBy` key in `tags` SHALL override the default.

#### Scenario: Default tag
- **WHEN** the module is called without `tags`
- **THEN** every tagged resource carries `ManagedBy = "terraform"`

#### Scenario: Additional tags
- **WHEN** `tags = { Project = "my-project" }`
- **THEN** every tagged resource carries `Project = "my-project"` and `ManagedBy = "terraform"`

#### Scenario: Override of the default tag
- **WHEN** `tags = { ManagedBy = "ci" }`
- **THEN** every tagged resource carries `ManagedBy = "ci"`

### Requirement: Core and connectivity outputs
The module SHALL expose `net_id`, the maps `subnet_ids`, `nat_service_ids`, `public_ip_ids`, `public_ips`, `net_peering_ids` and `net_access_point_ids`, each keyed by the key of the input that defines the object, and `dhcp_options_set_id` and `internet_service_id`, each `null` when the resource is not created. Each map SHALL be empty when its resource is not created.

#### Scenario: Minimal call outputs
- **WHEN** the module is called with a Net and subnets `public_a` and `public_b` and nothing optional
- **THEN** `subnet_ids` has the keys `public_a` and `public_b`, `dhcp_options_set_id` and `internet_service_id` are `null`, and the other maps are empty

### Requirement: Routing and services outputs
The module SHALL expose the maps `route_table_ids`, `load_balancer_dns_names` and `nic_ids`, each keyed by the key of the input that defines the object and empty when none is created. No output SHALL be sensitive.

#### Scenario: Empty maps
- **WHEN** the module is called without route tables, load balancers or NICs
- **THEN** `route_table_ids`, `load_balancer_dns_names` and `nic_ids` are empty maps
