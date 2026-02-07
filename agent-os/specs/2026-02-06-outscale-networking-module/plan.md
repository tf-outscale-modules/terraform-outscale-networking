# Outscale Networking Terraform Module — Implementation Plan

## Context

This project needs a Terraform module for managing Outscale networking resources. The repo has Agent OS standards and tooling configured but no Terraform code yet. This plan bootstraps the full module covering 10 resource categories across ~20 Outscale resource types, excluding VPN and Direct Link.

**Provider**: `outscale/outscale` ~> 1.0 (current latest: 1.3.2)
**Terraform**: >= 1.10 (per repo standards, OpenTofu 1.11 compatible)

---

## Task 1: Save Spec Documentation

Create `agent-os/specs/2026-02-06-outscale-networking-module/` with:

- **plan.md** — This full plan
- **shape.md** — Shaping notes (scope, decisions, context)
- **standards.md** — All 8 relevant standards content
- **references.md** — Outscale provider resource documentation notes

---

## Task 2: Create `versions.tf`

- `terraform.required_version = ">= 1.10"`
- `required_providers.outscale` with `source = "outscale/outscale"`, `version = "~> 1.0"`

---

## Task 3: Create `variables.tf`

All input variables, ordered: required first, then optional.

---

## Task 4: Create `locals.tf`

- `common_tags` — Merge of `{ ManagedBy = "terraform" }` with `var.tags`
- `enable_dhcp` — Boolean: true if any DHCP var is set
- Helper locals for cross-referencing keys

---

## Task 5: Create `core.tf`

Resources: Net, Subnets, DHCP options, Net attributes.

---

## Task 6: Create `connectivity.tf`

Resources: Internet service, public IPs, NAT services, net peerings, net access points.

---

## Task 7: Create `routing.tf`

Resources: Route tables, route table links, main route table link, routes.

---

## Task 8: Create `services.tf`

Resources: Load balancers, NICs.

---

## Task 9: Create `outputs.tf`

All outputs grouped by layer.

---

## Task 10-11: Create examples

Basic and complete examples.

---

## Task 12: Create tests

Terraform native tests.

---

## Task 13: Update README.md

Full README following standards.

---

## Task 14: Create scaffolding files

Pre-commit, tflint, editorconfig, cliff, mise, gitlab-ci, LICENSE.

---

## Verification

1. `tofu init` — Provider downloads successfully
2. `tofu validate` — No syntax/reference errors
3. `tofu fmt -check -recursive` — All files formatted
4. `tofu test` — All tests pass with `command = plan`
