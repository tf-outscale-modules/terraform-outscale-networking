# Security

## Credential Management

- Never commit secrets to `.tf` or `.tfvars` files
- Pass credentials via environment variables (`OSC_ACCESS_KEY`, `OSC_SECRET_KEY`) or a vault
- Use `mise.local.toml` (gitignored) for local API keys and tokens

## State Security

- State files may contain sensitive data in plaintext
- Always use encrypted remote backends for shared infrastructure
- Restrict access to state storage with appropriate IAM policies
- Never commit `.tfstate` or `.tfstate.backup` to version control

## Network Security Defaults

- Internet Service is **disabled by default** — explicit opt-in via `enable_internet_service = true`
- NAT Services are **disabled by default** — explicit opt-in via `enable_nat_services = true`
- Public IPs are **not created** unless explicitly defined
- Security groups are **not managed** by this module — pass existing IDs via `security_group_ids`

## Least Privilege

- Security group IDs for load balancers and NICs are passed by reference, not created
- Net peering auto-accept only works for same-account peerings — cross-account requires manual acceptance
- Net access points restrict service access to specific route tables

## Static Analysis

The CI pipeline runs:

1. **OSV Scanner** — Vulnerability scanning for dependencies
2. **TFLint** — Terraform linting with 10 enabled rules
3. **Pre-commit hooks** — Private key detection, formatting, documentation checks
4. **OpenTofu validate** — Syntax and reference validation

## Reporting

To report a security vulnerability, open a confidential issue in the GitLab project.
