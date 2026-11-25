# Design

## Context

Greenfield module scaffolded from `terraform-module-template`; no state exists, so nothing migrates and no `moved` block is needed. Motivation: see proposal.md. Provider `outscale/outscale` 1.9.0 (GA 2026-11-25, betas since 2026-10-12) introduced every resource used here; the schema was read from the provider's JSON schema and its documentation. Standards applied: quality-security (safe defaults, validate at the boundary, no silent weakening, pinned dependencies), quality-simplicity / quality-efficiency (smallest surface), terraform-providers, terraform-versioning, terraform-variables, terraform-outputs, terraform-code-style, terraform-naming, terraform-module-structure, terraform-security, terraform-testing; repository-versioning for the first tag.

Provider facts that shape the design (all introduced in 1.9.0):

| Resource | Arguments used | Notes |
|---|---|---|
| `outscale_oos_bucket` | `name` (optional, computed), `acl`, `force_delete` | no `tags`; `acl` and `grant` mutually exclusive; computed `id` (= name), `location_name`, `creation_date`, `permissions` |
| `outscale_oos_bucket_versioning` | `bucket`, `status` (`Enabled` \| `Suspended`) | not retroactive for encryption |
| `outscale_oos_bucket_encryption` | `bucket`, `encryption_type` (`AES256`; `aws:kms` maps to `AES256`) | computed `bucket_key_enabled` |
| `outscale_oos_bucket_policy` | `bucket`, `policy` (JSON string) | |
| `outscale_oos_bucket_cors` | `bucket`, `rule` set (`allowed_headers`, `allowed_methods`, `allowed_origins`, `expose_headers`, `max_age_seconds`) | `rule` is a set block |
| `outscale_oos_bucket_lifecycle` | `bucket`, `rule` set (`id`, `status`, `filter`, `expiration`, `noncurrent_version_expiration`, `abort_incomplete_multipart_upload`) | `filter` is required (`{}` = all objects); tags need `and = { prefix, tags }`; docs put it after versioning |

Provider configuration lives with the caller. The provider block takes `access_key_id`, `secret_key_id`, `region` and an `oos { endpoint, region }` block; the environment equivalents are `OSC_ACCESS_KEY`, `OSC_SECRET_KEY`, `OSC_REGION` and `OSC_ENDPOINT_OOS` (the pre-1.6 `OUTSCALE_*` names are gone). The module has no provider block (terraform-module-structure); the examples configure `provider "outscale" {}` in their own `providers.tf` (terraform-providers).

## Goals / Non-Goals

**Goals:**
- One `buckets` map producing hardened buckets with the five optional settings.
- Plan-time failure for inputs that can never be valid, plan-time warning for legal but risky ones (terraform-security "Guardrails").
- Empty second plan after apply.

**Non-Goals:**
- Objects, copies, retention, presigned URLs, `grant`, `object_lock` (see proposal for why).
- Tags (the bucket resource has none), bucket notifications, website hosting, logging (no provider resource in 1.9.0).
- Creating the credentials or access keys used by consumers of the bucket.

## Decisions

**D1. Map keyed by bucket name, `for_each` everywhere.** The key is the bucket name sent as `name`, so the address is stable and a reorder never recreates anything (terraform-code-style "Expressions"). Alternative: `name` attribute plus an arbitrary key; rejected as a second source of truth for the same value. Cost: renaming a bucket is a replace, which is true of the API anyway. One resource label `this` per type (terraform-naming); optional resources use a filtered map, not `count`.

**D2. Per-feature resources instead of inline arguments.** The provider splits settings into their own resources, so each setting follows the entry: versioning and encryption always for an entry unless opted out, policy and CORS and lifecycle only when set. Locals build the filtered maps (`local.policies`, `local.cors`, `local.lifecycles`); no `dynamic` block is needed for the singleton resources, only for the `rule` set blocks.

**D3. Secure defaults, because the module is new and has no state** (quality-security "Safe defaults", "No silent weakening"):
- `enable_encryption = true` creating `AES256` encryption. Opt-out is `false`, visible in review. Alternative: no default and require callers to choose; rejected because every caller then repeats the same line.
- `versioning_status = "Enabled"`. Gates destructive actions (an overwrite or delete keeps a recoverable version) at the cost of storage for old versions; the lifecycle rule `noncurrent_version_expiration_days` is the documented counter-measure and the complete example uses it. This is the decision most open to challenge (cost versus protection), see Open Questions.
- `acl = null`: nothing is sent, the server keeps private. A literal `"private"` default would be equivalent, but sending only what the caller set follows terraform-variables "optional attribute with an invented default". `public-read-write` is rejected by validation (never acceptable, quality-security "Validate at the boundary"); `public-read` and `authenticated-read` stay available.
- `force_delete = false` explicit default: a destroy fails on a non-empty bucket instead of purging objects and versions (quality-security "destructive actions gated"). It cannot bypass an object lock either.

**D4. Public exposure is a `check`, not a validation.** A public-read bucket, an `Allow` + `Principal "*"` statement and a `*` CORS origin are legal and sometimes intended (static assets). terraform-security says to report those with `check` blocks and keep `validation` for never-acceptable input. The check parses the policy with `jsondecode` for the principal test; a statement `Principal` may be the string `"*"` or `{ AWS = "*" }`, both handled. A `check` never fails the apply, so the warning is advisory by design.

**D5. Input types.** `buckets = map(object({ acl = optional(string), force_delete = optional(bool, false), versioning_status = optional(string, "Enabled"), enable_encryption = optional(bool, true), policy = optional(string), cors_rules = optional(list(object({...})), []), lifecycle_rules = optional(list(object({...})), []) }))`, default `{}` (terraform-variables: specific types, no `any`, booleans prefixed `enable_`). CORS and lifecycle rules are lists for readability, converted to the provider's set blocks; order is irrelevant to the server. The template's `create` toggle is dropped: it is a verb, `buckets = {}` already means "create nothing" and a second switch is redundant (quality-simplicity). Lifecycle items flatten the provider's nested `filter` / `expiration` objects into `prefix`, `tags`, `expiration_days`, `expired_object_delete_marker`, `noncurrent_version_expiration_days`, `abort_incomplete_multipart_upload_days`; absolute `expiration.date` is left out (a past date expires everything at once, a footgun not worth a v0.1 argument). When `tags` is set the module builds `filter = { and = { prefix = coalesce(prefix, ""), tags } }` as the provider requires; otherwise `filter = { prefix }` or `{}`.

**D6. Validations** (each with a unit test using `expect_failures`): bucket key pattern (no dots because dotted names break virtual-hosted TLS), `acl` enumeration, `versioning_status` enumeration, `jsondecode` validity of `policy` (via `can`, the standard's allowed use: it validates, it does not hide a wrong input), CORS methods and `max_age_seconds >= 0`, lifecycle `status`, at least one action, unique ids per bucket, and the documented incompatibility between a tag filter and the delete-marker or multipart actions, and `expired_object_delete_marker` with `expiration_days` (the API rejects it with MalformedXML "Expiration action includes more than one time", found in the live test). Validations on `buckets` are written as `alltrue([for ...])`.

**D7. Perpetual diff.** The policy is sent as `jsonencode(jsondecode(var))`, which sorts keys and strips whitespace; the server is expected to return a JSON the provider compares semantically, to be confirmed in the real apply (task 5.2). CORS and lifecycle `rule` are set blocks and the module passes sets for the set-typed attributes, so order cannot cause a diff. Lifecycle rule `id` is required in the module (the provider would generate a random one, which is stable in state but unreadable in review). `encryption_type` is always sent as `AES256`, the form the server reports. No `ignore_changes` is used.

**D8. Ordering.** `outscale_oos_bucket_lifecycle` gets `depends_on = [outscale_oos_bucket_versioning.this]`, as in the provider documentation, since lifecycle rules for noncurrent versions need the versioning state to exist first (the one `depends_on` the implicit graph cannot express, terraform-outputs "depends_on only when Terraform cannot infer").

**D9. Outputs** (terraform-outputs): `bucket_ids`, a map by key, no sensitive value. A `bucket_location_names` output was planned and removed after the live test: `location_name` is null on OOS eu-west-2. `creation_date`, `permissions` and `bucket_key_enabled` are not exported because no consumer wires them; adding keys later is a minor change.

**D10. Versions.** `required_version >= 1.11.0` (organisation floor, terraform-providers, higher than the template's `>= 1.10.0`, which is stale), provider `~> 1.9` because the OOS resources first exist there; raising it later is a major bump (terraform-versioning). The first tag is `v0.1.0`: repository-versioning keeps `0.x` until the contract is stable, and the provider resources are a day old. `1.0.0` is reserved for after a clean real apply and a first consumer. Commit subject example: `Add OOS buckets with versioning, encryption, policy, CORS and lifecycle`.

**D11. Tests are plan-mode with `mock_provider "outscale"`** (terraform-testing), no credentials needed. The integration fixture of terraform-testing, an apply against a real account with a second-plan check, is not part of the unit suite; task 5.2 runs it by hand before the tag and records the result in the README compatibility table.

**D12. Credentials and state.** No input carries a secret, so the write-only rule does not apply (terraform-security "Keep secret material out of state"). `SECURITY.md` records what lands in state: bucket name, `creation_date`, the policy text, CORS and lifecycle content and the S3 owner and grantee ids in `permissions`. Callers keep keys in `OSC_ACCESS_KEY` / `OSC_SECRET_KEY` or a vault. Bucket policies in the examples are least-privilege (named principals, listed actions), never `*` on `*`.

## Risks / Trade-offs

- [Early-adopter risk: the OOS resources are new, GA on 2026-11-25 after betas from 2026-10-12, and behaviour on edge cases such as lifecycle filters, policy round-trips or `bucket_key_enabled` may change in a 1.9.x patch] → pin `~> 1.9`, stay in `0.x`, run the real apply and empty-second-plan check before tagging, and keep the unit tests on module behaviour rather than provider internals.
- [Versioning on by default raises storage cost] → documented opt-out `Suspended` and the lifecycle rule example; flagged for review.
- [Encryption on by default might be a no-op if OOS already encrypts at rest, or `AES256` could change if Outscale adds customer keys] → the argument is explicit, so a future provider change shows in the plan; revisit when `aws:kms` gains meaning.
- [Bucket names are one namespace per region and may already be taken] → the apply fails with the API error; the README tells callers to prefix names; no random suffix is added (it would hide the real name from the contract).
- [`check` warnings are advisory and can be ignored in CI] → acceptable per terraform-security; CI trivy/checkov scans cover the rest where they understand OOS.
- [Dropped `grant`, `object_lock`, `date` expiration reduce coverage] → each is a later minor; the 0.x contract makes room.
- [Policy parsed in HCL cannot see every unsafe policy shape] → the check covers the common `Principal "*"` case only and says so in the README Known Limitations.

## Migration Plan

New module, no state to migrate. Release: merge, `mise run changelog`, tag `v0.1.0` on `main` (repository-versioning, tag equals declared version). Rollback: delete the tag and the unreleased consumers; no existing consumer depends on it.

## Open Questions

Resolved by the live test of 2026-11-25 (provider 1.9.0, eu-west-2, three buckets, 11 resources; see tasks 5.2):
- Policy JSON: the server returns it in a form that keeps the second plan empty after `jsonencode(jsondecode())`.
- Encryption: OOS does not encrypt by default (`GetBucketEncryption` returns ServerSideEncryptionConfigurationNotFoundError on a bucket without the resource), so `enable_encryption = true` is a real protection, not a no-op. Removing the resource removes the configuration and re-adding restores `AES256` with an empty plan.
- Lifecycle: `expired_object_delete_marker` together with `expiration_days` is rejected by the API; a delete-marker-only rule works. The module now validates this.
- `location_name` is null on this region; the output was dropped.

Still open (maintainers): versioning default `Enabled` vs unset (protection against accidental deletion versus storage cost).
