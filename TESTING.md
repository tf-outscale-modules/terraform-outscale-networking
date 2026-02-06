# Testing

## Test Framework

This module uses Terraform's native test framework (`.tftest.hcl` files).

## Running Tests

```bash
# Using OpenTofu (recommended)
tofu init
tofu test

# Using Terraform
terraform init
terraform test
```

## Test Structure

Tests are located in `tests/main.tftest.hcl` and organized by layer:

| Category | Tests | Description |
|----------|-------|-------------|
| Core Resources | 2 | Net creation, subnet count and properties |
| DHCP | 2 | Skipped when disabled, created when enabled |
| Connectivity | 5 | Internet Service, NAT, peerings, access points |
| Routing | 2 | Empty when undefined, created with subnet links |
| Services | 2 | Load balancers, NICs skipped when disabled |
| Outputs | 5 | Correct types, null for disabled, empty maps |
| Validation | 3 | Invalid CIDR, empty subnets, bad tenancy rejected |

All tests use `command = plan` — no real infrastructure is created.

## CI Validation

The GitLab CI pipeline runs these checks automatically:

1. `tofu init -backend=false` — Provider initialization
2. `tofu validate` — Syntax and reference validation
3. `tofu fmt -check -recursive` — Formatting check
4. `tflint --recursive` — Linting
5. `pre-commit run -a` — All pre-commit hooks

## Examples as Tests

Both `examples/basic/` and `examples/complete/` are valid Terraform configurations. CI runs `tofu validate` against the entire repository, which includes these examples.

## Writing New Tests

Follow these patterns:

```hcl
# Test that a feature is skipped when disabled
run "skips_feature_when_disabled" {
  command = plan

  assert {
    condition     = length(outscale_resource.this) == 0
    error_message = "Resource should not be created when disabled"
  }
}

# Test that a feature is created when enabled
run "creates_feature_when_enabled" {
  command = plan

  variables {
    enable_feature = true
    feature_config = { ... }
  }

  assert {
    condition     = length(outscale_resource.this) == 1
    error_message = "Resource should be created when enabled"
  }
}

# Test that invalid input is rejected
run "rejects_invalid_input" {
  command = plan

  variables {
    my_var = "invalid-value"
  }

  expect_failures = [
    var.my_var,
  ]
}
```
