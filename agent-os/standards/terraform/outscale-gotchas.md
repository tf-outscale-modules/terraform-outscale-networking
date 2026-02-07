# Outscale Provider Gotchas

## Load Balancer: Single Subnet Only

Outscale API error 8033 rejects multiple subnets per LB. Use one LB per subnet for multi-AZ.

```hcl
# Good
subnet_keys = ["public_a"]

# Bad — error 8033
subnet_keys = ["public_a", "public_b"]
```

## Net Peering: Cross-Account Requires accepter_owner_id

When `accepter_net_id` belongs to a different account, `accepter_owner_id` is mandatory.

## DHCP Option: Destroy Race Condition

Provider bug: deletes DHCP option, then tries to unlink from Net — fails because the option no longer exists.

- `depends_on = [outscale_net.this]` on dhcp_option ensures correct inter-resource ordering but cannot fix internal provider logic
- Workaround: `tofu destroy -auto-approve || tofu destroy -auto-approve`
- Alt workaround: `tofu state rm` the orphaned dhcp_option

## HTTPS Listener: Requires server_certificate_id

LB listeners with `load_balancer_protocol = "HTTPS"` require `server_certificate_id`. No default or self-signed fallback.
