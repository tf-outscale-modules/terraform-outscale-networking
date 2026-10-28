## Why

Writing the `adopt-openspec` baseline surfaced code and documentation gaps. Each one is
checked against the code.

## What Changes

| Issue | Decision | Breaking |
|-------|----------|----------|
| `enable_nat_services` description says it requires `enable_internet_service = true`, not enforced | Code fix: a `check` block warns. Not a validation: a NAT service can use an Internet Service attached to the Net outside the module, so rejecting would break working configs | No |
| `route_tables` description says one target per route, not enforced | Code fix: a validation rejects a route with several target types (it would create several routes to one destination, which the API refuses); a `check` warns on a route with no target (it creates nothing today, so rejecting would break working configs). `use_internet_service` and `gateway_id` share one resource and count as one target | No |
| `use_internet_service = true` without `enable_internet_service` fails with an index error on `outscale_internet_service.this[0]` | Code fix: a validation on `route_tables` with a readable message (the module floor is 1.10, so a validation can read `enable_internet_service`) | No (only configs that failed) |
| README `source` says `outscale-network.git` | Doc fix: `outscale-networking.git` | No |
| README says all connectivity/service resources use `enable_*` flags, but `public_ips`, `route_tables` and `nics` are created whenever their map is not empty | Doc fix | No |

Semver: **patch** (fixes and documentation; no input, output, default or address changes;
the new `check` blocks only warn).

State: no new resource or secret.

## Impact

`variables.tf`, new `checks.tf`, `README.md`, `tests/main.tftest.hcl`, `examples/complete`
(unchanged, no input changes), specs `route-tables` and `internet-access`.
