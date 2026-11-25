# Spec Delta

## Purpose

Cross-cutting contract of the module: supported tooling and provider, caller-side provider configuration, the `buckets` input shape and its name validation, the outputs and the stable second plan.

## ADDED Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.11.0"` and pin `outscale/outscale` with `~> 1.9` in `versions.tf`, and SHALL work on OpenTofu and Terraform. It SHALL use the `outscale_oos_*` resources of the Outscale provider and no other provider.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** only `outscale/outscale` resolves, to a 1.x release at or above 1.9

#### Scenario: Core below the floor
- **WHEN** the module is initialised with OpenTofu or Terraform 1.10
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Provider below the floor
- **WHEN** the caller's lock file holds `outscale/outscale` 1.8.x
- **THEN** `init` rejects it because the OOS resources do not exist there

### Requirement: No provider or backend configuration
The module SHALL NOT contain `provider {}` or `backend {}` blocks. The caller SHALL configure the `outscale` provider (credentials, region and, when needed, the `oos { endpoint, region }` block or `OSC_ENDPOINT_OOS`) and the state backend, and the README SHALL say so.

#### Scenario: Provider block inside the module
- **WHEN** a change adds `provider "outscale" {}` or a `backend` block to a module file
- **THEN** it is moved to the caller or to the example's `providers.tf`, and the module only declares `required_providers`

#### Scenario: Region only through the environment
- **WHEN** a caller sets `OSC_REGION` and `provider "outscale" {}` without an `oos` block
- **THEN** the module plans against the OOS endpoint of that region without any module input

### Requirement: Buckets input
The module SHALL expose one input, `buckets`, a `map(object({...}))` keyed by bucket name, with default `{}`; every attribute of an entry is optional. No other input exists in the first release.

#### Scenario: Empty call
- **WHEN** the module is called without `buckets`
- **THEN** the plan contains no resource and every output is an empty map

#### Scenario: Minimal entry
- **WHEN** `buckets = { "acme-logs" = {} }`
- **THEN** the plan creates the bucket named `acme-logs` with the secure defaults of the `buckets` capability

#### Scenario: Entry removed
- **WHEN** a key is removed from `buckets`
- **THEN** only the resources of that key are planned for destruction and the other buckets are untouched

### Requirement: Bucket name validation
Each key of `buckets` SHALL be 3 to 63 characters of lowercase letters, digits and hyphens, starting and ending with a letter or digit. The validation error SHALL name the accepted pattern.

#### Scenario: Valid name
- **WHEN** a key is `acme-logs-01`
- **THEN** the plan succeeds

#### Scenario: Uppercase or underscore
- **WHEN** a key is `Acme_Logs`
- **THEN** the plan fails with "Bucket names must be 3-63 characters of lowercase letters, digits and hyphens, starting and ending with a letter or digit."

#### Scenario: Name too short or ending in a hyphen
- **WHEN** a key is `ab` or `acme-`
- **THEN** the plan fails with the same bucket name error

### Requirement: Outputs
The module SHALL output `bucket_ids`, a map keyed like `buckets` holding the bucket id (equal to its name). It is not sensitive because no secret exists in the module.

#### Scenario: Two buckets
- **WHEN** two entries are planned
- **THEN** `bucket_ids` has exactly those two keys

#### Scenario: Output consumed downstream
- **WHEN** another module reads `module.oos.bucket_ids["acme-logs"]`
- **THEN** it receives the bucket name usable as the `bucket` argument of other OOS resources

### Requirement: Empty second plan
Values SHALL be sent in the form the server reads back so that a `plan` directly after `apply` is empty, including the bucket policy JSON and the set-typed CORS and lifecycle rule blocks.

#### Scenario: Policy given with different key order
- **WHEN** a caller passes a policy JSON whose keys are not in the order the server returns
- **THEN** the module normalises it before sending and the second plan is empty

#### Scenario: Re-plan after apply
- **WHEN** `plan` runs right after a successful `apply` of the complete example
- **THEN** it reports no change
