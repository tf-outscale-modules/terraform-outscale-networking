## Context

`outscale_load_balancer.this` (`services.tf`) and `outscale_net_peering.this` (`connectivity.tf`) expose only part of the provider schema. Provider 1.8.0 (schema and source `internal/services/oapi/resource_load_balancer.go`, `resource_net_peering.go` inspected) provides, all `Optional` + `Computed`:

| Resource | Argument | Type | On change |
|---|---|---|---|
| `outscale_load_balancer` | `secured_cookies` | bool | in-place (`UpdateLoadBalancer`) |
| `outscale_load_balancer` | `public_ip` | string (the IP address, not an id) | in-place (`UpdateLoadBalancer`) |
| `outscale_load_balancer` | `subregion_names` | list(string) | **forces replacement**; config validator `Conflicting(subnets, subregion_names)` |
| `outscale_net_peering` | `source_net_account_id` | string | **forces replacement** |

Introduced at or before 1.8.0, the current pin; the pin `~> 1.8` and `required_version >= 1.10` stay (no major bump, `terraform-versioning`). Provider 1.9.0 is not required.

## Goals / Non-Goals

**Goals:** expose the four arguments opt-in, reject at plan time combinations the provider refuses, change nothing for existing callers.

**Non-Goals:** VPN stack, load balancer policies/listener rules/attributes/VM registration, server certificates (future changes); managing the accepter side of a cross-account peering; any new output.

## Decisions

1. **Input shape.** Three new `optional()` attributes on `load_balancers` and one on `net_peerings`, all `null` by default ("argument not sent", `terraform-variables`). Because every argument is `Optional` + `Computed`, `null` never plans a diff against state, so existing users see an empty plan and a second plan after apply stays empty.
2. **`public_ip_key` instead of an IP string.** The module already owns `outscale_public_ip.this` (standalone, keyed). The load balancer sets `public_ip = outscale_public_ip.this[each.value.public_ip_key].public_ip` when the key is set, else `null`. The reference gives implicit ordering and removes a second way to pass an IP (`quality-simplicity`). A bring-your-own IP from another module is not supported by this input; if needed it is a later, separate attribute. The provider takes the address (`public_ip` attribute of `outscale_public_ip`), not the allocation id, which is what is sent. The output `public_ips` already exposes the address to callers.
3. **`subnets` becomes `null` when `subnet_keys` is empty.** Today the module sends `subnets = []`. The provider's `Conflicting` validator counts a configured empty list as set, so `subregion_names` would always conflict. `subnets = length(subnet_keys) > 0 ? [...] : null`. Impact on existing state: a load balancer in a Net always has non-empty `subnet_keys` (the API requires a Subnet in a Net), so the expression is unchanged for every valid existing call.
4. **Validations (hard conflicts), in `variables.tf` on `load_balancers`:**
   - `subnet_keys` and `subregion_names` not both non-empty (provider `Conflicting`).
   - `public_ip_key` only with `load_balancer_type = "internet-facing"` (API: public IP is internet-facing only).
   - `public_ip_key`, when set, is a key of `var.public_ips` (cross-variable validation, available since OpenTofu/Terraform 1.9, below the 1.10 floor); this gives a named error instead of an index error.
   On `net_peerings`: `source_net_account_id`, when set, matches `^[0-9]{12}$` (Outscale account ids are 12 digits). Messages name the accepted values.
5. **Cross-account peering.** `source_net_account_id` is the account that owns the module's Net; `accepter_owner_id` (existing) is the other account. The accepter account must accept the peering itself; `auto_accept = true` only works within one account. The module does not accept for another account (no provider alias in the module, `AGENTS.md`); this is documented in the `net_peerings` description and README. No cross-account `auto_accept` validation is added: the module cannot tell whether `accepter_owner_id` equals the caller's account.

## Replacement impact and perpetual-diff avoidance

- `secured_cookies`, `public_ip`: in-place update. Switching `public_ip_key` to another key re-associates the IP in place (brief reload, provider waits for `active`).
- `subregion_names`, `source_net_account_id`: forced replacement when changed to a value different from state. Adding them to an existing resource with the value the server already reports is a no-op; setting a different value replaces the load balancer/peering. Replacement is called out in the variable descriptions and the merge request notes.
- Removing an attribute back to `null` never plans a change (`Computed`): the previous cookie setting or public IP stays on the load balancer. To change it, set the new value explicitly. Documented in the descriptions.
- Values are sent in the form the server reads back: IP address string, bool, 12-digit account id, Subregion names as listed by the API (e.g. `eu-west-2a`). A second plan is empty.
- No `moved` blocks: no address changes. Existing resources keep their address and arguments.

## Risks / Trade-offs

- A caller with `subnet_keys = []` and a Net-less intent today sends `subnets = []`; it now sends nothing. Same API effect; accepted.
- The 12-digit rule is a module assumption about Outscale account ids; it is limited to the new attribute so it cannot break existing calls.
- `public_ip_key` couples a load balancer to a standalone IP: destroying the IP while the load balancer exists fails at the API; Terraform orders destroy correctly through the reference.

## Migration

Upgrade is a drop-in minor release; no state migration. Standards cited: `terraform-versioning`, `terraform-variables`, `terraform-security`, `terraform-code-style`.
