# Applicable Standards

This spec references the following Agent OS standards:

1. **global/code-style** — HCL formatting (2-space indent, block ordering, expressions)
2. **global/documentation** — README structure, terraform-docs, variable descriptions, examples
3. **global/security** — No secrets in code, sensitive markers, network defaults
4. **global/versioning** — Semver, git tags, pre-1.0 strategy
5. **terraform/module-structure** — File layout (versions.tf, variables.tf, outputs.tf, etc.)
6. **terraform/naming** — snake_case, `this` for single resources, no type in name
7. **terraform/variables** — Ordering, descriptions, types, validation, enable_ prefix
8. **terraform/outputs** — Descriptions, grouped by resource, match resource order
9. **terraform/providers** — Pessimistic constraint, no provider blocks in modules
10. **testing/terraform-tests** — Native .tftest.hcl, command = plan, what to test

See `agent-os/standards/` for full content of each standard.
