# Outscale Networking Module Patterns

## Key-Based Cross-References

Resources reference each other by map keys, not IDs. Users never need to know resource IDs.

```hcl
# Routes reference NAT services by key
routes = [{
  destination_ip_range = "0.0.0.0/0"
  nat_key              = "nat_a"  # key from nat_services map
}]

# NAT services reference subnets by key
nat_services = {
  nat_a = { subnet_key = "public_a" }  # key from subnets map
}
```

All key-based fields: `subnet_key`, `subnet_keys`, `nat_key`, `peering_key`, `nic_key`, `route_table_keys`, `use_internet_service`

## Feature Flag + Feature Map

Optional features require both an `enable_*` boolean AND a config map:

```hcl
for_each = var.enable_nat_services ? var.nat_services : {}
```

- Boolean controls creation, map defines resources
- Empty map + enabled = no resources (safe)
- Populated map + disabled = no resources (explicit off)

## Route Splitting by Target Type

Routes are split into 4 `outscale_route` resources by target type:
- `outscale_route.gateway` — IGW or external gateway
- `outscale_route.nat` — NAT service
- `outscale_route.peering` — Net peering
- `outscale_route.nic` — Network interface

This avoids conditional logic within a single resource.

## use_internet_service Self-Reference

Routes can reference the module's own Internet Service without knowing its ID:

```hcl
routes = [{
  destination_ip_range = "0.0.0.0/0"
  use_internet_service = true  # resolves to outscale_internet_service.this[0].internet_service_id
}]
```

Keeps `gateway_id` available for external gateways.
