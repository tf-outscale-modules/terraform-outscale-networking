## Why

Load balancers created by the module cannot use three provider capabilities that production setups need: secure cookies, a fixed (allow-listable) public IP for an internet-facing load balancer, and Subregion placement. Net peerings cannot state the source account, which a cross-account peering needs. All four arguments exist in provider `outscale/outscale` 1.8.0 (the current pin `~> 1.8`), so no provider floor change is needed.

## What Changes

- `load_balancers` entries gain three optional attributes, all defaulting to `null` ("provider default, argument not sent"):
  - `secured_cookies` (`bool`): enables secure cookies on the load balancer.
  - `public_ip_key` (`string`): key of an entry of `public_ips`; the load balancer is created with that standalone public IP (internet-facing only).
  - `subregion_names` (`list(string)`): Subregions for a load balancer outside a Net (public Cloud); mutually exclusive with `subnet_keys`.
- `net_peerings` entries gain `source_net_account_id` (`string`, default `null`): the account that owns the module's Net, required by the API for a cross-account peering.
- New `validation` blocks reject the combinations the provider/API refuses: `subnet_keys` with `subregion_names`, `public_ip_key` on a non-internet-facing load balancer or naming no `public_ips` key, and a malformed `source_net_account_id`.
- When `subnet_keys` is empty the module now sends no `subnets` argument (`null`) instead of an empty list, so that `subregion_names` does not conflict with an empty `subnets`.
- Documentation: the accepter side of a cross-account peering belongs to the other account and cannot be accepted or managed by this module; this is stated in the variable description and README.
- Unit tests in `tests/main.tftest.hcl`, `examples/complete` update, README regeneration.
- No new output, no new resource, no secret-bearing input (nothing lands in state beyond what the resources already store; the public IP is not a secret).
- Semver: **minor** (`terraform-versioning`: new `optional()` attributes with `null` default). No input or output changes type, default or meaning; no existing plan changes.
- Out of scope, future work: VPN stack (virtual gateway, client gateway, VPN connection), load balancer policies, listener rules, attributes and VM registration, server certificates.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `services`: load balancers accept `secured_cookies`, `public_ip_key` and `subregion_names`, with validations.
- `private-connectivity`: peerings accept `source_net_account_id` for cross-account peerings, with a documented accepter-side limit.

## Impact

- Code: `variables.tf` (`load_balancers`, `net_peerings` types and validations), `services.tf` (`outscale_load_balancer.this`), `connectivity.tf` (`outscale_net_peering.this`).
- Tests/examples/docs: `tests/main.tftest.hcl`, `examples/complete`, README (terraform-docs block regenerated).
- Dependencies: none; provider pin stays `~> 1.8`.
- Standards applied: `terraform-versioning` (minor), `terraform-variables` (optional attributes default `null`, validations naming accepted values), `terraform-security` (plan-time rejection of illegal input; no secret involved), `quality-simplicity` (reference an existing public IP by key rather than a second IP mechanism).
