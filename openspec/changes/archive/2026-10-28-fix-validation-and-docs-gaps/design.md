## Decisions

- **Route target count**: validation on `route_tables` counts, per route,
  `use_internet_service || gateway_id != null`, `nat_key`, `peering_key` and `nic_key`
  as at most one target. The gateway pair stays one target because both feed
  `outscale_route.gateway`, where `use_internet_service` wins.
- **Internet Service route**: second validation on `route_tables` reading
  `var.enable_internet_service` (cross-variable validation needs OpenTofu/Terraform 1.9, the
  module floor is 1.10).
- **Warnings**: `checks.tf` with `check "nat_services_need_internet_service"` and
  `check "routes_have_target"`. Checks warn and never block, so working configs stay valid.
- No provider, backend or CLI change; no address changes, so no `moved` block.
