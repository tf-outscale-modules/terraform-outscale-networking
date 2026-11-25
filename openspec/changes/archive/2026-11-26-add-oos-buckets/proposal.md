# Proposal

## Why

Teams that run on Outscale have no Leminnov module for Outscale Object Storage (OOS), the S3-compatible service, so buckets are created by hand or with ad-hoc `aws_s3_*` resources pointed at the OOS endpoint. Provider `outscale/outscale` 1.9.0 (released 2026-11-25) adds native `outscale_oos_*` resources, which removes the need for the `aws` provider and its S3 endpoint workarounds. A module with secure defaults gives every consumer the same hardened bucket from one input.

## What Changes

- New module surface, no existing state and nothing to migrate: `buckets`, a map of bucket objects keyed by bucket name, creates for each entry an `outscale_oos_bucket` and, driven by the entry, `outscale_oos_bucket_versioning`, `outscale_oos_bucket_encryption`, `outscale_oos_bucket_policy`, `outscale_oos_bucket_cors` and `outscale_oos_bucket_lifecycle`.
- Secure defaults, opt-out explicit in review (quality-security "Safe defaults"): versioning `Enabled`, default encryption `AES256` on, bucket private, `force_delete = false`. `public-read-write` is rejected by validation; `public-read` and a policy that allows everyone (`Principal = "*"`) are legal but reported by a `check` block.
- Output `bucket_ids`, a map keyed like the input (a `bucket_location_names` output was dropped after the live test: the provider returns a null `location_name` on OOS eu-west-2).
- Provider floor `outscale/outscale ~> 1.9` (first release with the OOS resources), `required_version >= 1.11.0` (organisation floor, terraform-providers). No `provider {}` block: the caller configures credentials, region and optionally `oos { endpoint, region }`.
- Repository scaffolding from the template is already in place; this change adds the first module code, tests, examples, README block, `SECURITY.md` state table and `TESTING.md`.
- Out of scope for the first release (each can land later as a minor): `outscale_oos_object`, `outscale_oos_object_copy`, `outscale_oos_object_retention`, `outscale_oos_presigned_url`, and the bucket `grant` and `object_lock` arguments. The presigned URL carries a signature derived from the secret key and would land in state as a bearer credential until it expires, and object resources write object content and metadata into state; neither belongs in an infrastructure module. `acl` covers the canned permissions; `object_lock` in COMPLIANCE mode cannot be undone by anyone, so it needs its own reviewed change.
- Semver classification (terraform-versioning, repository-versioning): this is a brand-new module and the provider's OOS resources went GA only today (1.9.0, 2026-11-25) after betas from 2026-10-12, so the contract is not yet proven. The first release is **`0.1.0`**; `1.0.0` is reached only when the input and output shapes have survived a real apply and a first consumer. Every removed or renamed input or output before then is still documented in the CHANGELOG. No input or output changes type, default or meaning (nothing exists yet).
- What lands in state: bucket names, creation dates, the bucket policy JSON, CORS and lifecycle rule contents, canned ACL, and the owner/grant identifiers in the computed `permissions` attribute (S3 user IDs and account IDs, not secrets). No secret-bearing input exists: credentials belong to the caller's provider block, so the write-only rule of terraform-security does not apply. `SECURITY.md` carries the table.
- Known provider and API limits to document: `outscale_oos_bucket` has no `tags` argument, so the Project/Environment tag convention of the compute module cannot apply; bucket names are global to the region's namespace; lifecycle expiry is asynchronous; `aws:kms` currently behaves as `AES256`; versioning is not retroactive for encryption.
- Provider docs: https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket and the sibling `oos_bucket_*` pages; provider config https://github.com/outscale/terraform-provider-outscale/blob/master/docs/index.md. Early-adopter risk: the resources are weeks old, their documentation is thin on edge cases and a 1.9.x patch may change plan behaviour; the `~> 1.9` pin follows the minors, and the release stays in 0.x until an apply against a real account is clean.

## Capabilities

### New Capabilities
- `module-contract`: supported tooling and provider pin, no provider/backend block, caller-side provider configuration, `buckets` input shape, bucket name validation, empty default, outputs, empty second plan.
- `buckets`: what each bucket entry produces and its secure defaults: bucket, ACL and force-delete, versioning, encryption, policy, CORS, lifecycle, plus the `check` warnings for public exposure.

### Modified Capabilities

None (`openspec/specs/` is empty).

## Impact

- New or changed files: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf` (only if needed), `versions.tf` (already pinned), `tests/main.tftest.hcl`, `examples/basic`, `examples/complete` (each with its own `providers.tf` and README), `README.md`, `SECURITY.md`, `TESTING.md`, `CHANGELOG.md` (git-cliff).
- Dependency: `outscale/outscale ~> 1.9`; no new tool.
- Consumers: none yet; the first call pins `?ref=v0.1.0`.
