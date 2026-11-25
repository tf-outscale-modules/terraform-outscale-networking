# Tasks

Standards to fetch before editing HCL (`openspec show <id> --type spec --store terraform`): terraform-code-style, terraform-variables, terraform-outputs, terraform-naming, terraform-security, terraform-testing; and quality-security from the quality store.

## 1. Bucket core and input contract

- [x] 1.1 Remove the template placeholder text from `main.tf`, `variables.tf` (including the template `create` variable) and `outputs.tf`; verify `grep -rn "TODO" *.tf` returns nothing.
- [x] 1.2 Declare `buckets` in `variables.tf` with the object type of design D5, default `{}`, the key-pattern, `acl` and `force_delete` validations; verify `tofu validate` passes.
- [x] 1.3 Add `outscale_oos_bucket.this` (`for_each = var.buckets`, `name = each.key`, `acl`, `force_delete`) and output `bucket_ids` (the `bucket_location_names` output was removed after the live test); verify `tofu validate`.
- [x] 1.4 In `tests/main.tftest.hcl` add a `mock_provider "outscale"` and plan runs for: empty call, minimal entry, two buckets, rejected key (`Acme_Logs`, `ab`, `acme-`), rejected ACL (`public-read-write`); verify `tofu test` passes with `expect_failures = [var.buckets]` for the rejected inputs.
- [x] 1.5 Update `examples/basic` (one bucket, own `providers.tf` and README with `init`/`plan` commands and the `OSC_*` variables); verify `mise run test:examples` validates it.

## 2. Versioning and encryption

- [x] 2.1 Add `versioning_status` (enum validation) and `enable_encryption`; add `outscale_oos_bucket_versioning.this` and `outscale_oos_bucket_encryption.this` (`AES256`) with filtered `for_each`; verify `tofu validate`.
- [x] 2.2 Add tests: default creates both, `Suspended`, `enable_encryption = false` skips only that bucket, rejected status `Disabled`; verify `tofu test`.
- [x] 2.3 Extend `examples/complete` with one bucket per mode; verify `mise run test:examples`.

## 3. Policy and CORS

- [x] 3.1 Add `policy` (`can(jsondecode())` validation) and `cors_rules` (methods enum, `max_age_seconds >= 0`) to the type; add `outscale_oos_bucket_policy.this` (value `jsonencode(jsondecode(...))`) and `outscale_oos_bucket_cors.this` with a `dynamic "rule"` over filtered maps in `locals.tf`; verify `tofu validate`.
- [x] 3.2 Add tests: no policy, valid policy, `"not json"` rejected, no CORS, two rules, `PATCH` rejected, `-1` rejected; verify `tofu test`.
- [x] 3.3 Add a least-privilege policy (named principal, listed actions, no `*` on `*`) and two CORS rules to `examples/complete`; verify `mise run test:examples`.

## 4. Lifecycle and public-exposure checks

- [x] 4.1 Add `lifecycle_rules` with the validations of the `buckets` spec (unique ids, status enum, at least one action, tags versus delete marker / multipart); add `outscale_oos_bucket_lifecycle.this` with `depends_on = [outscale_oos_bucket_versioning.this]` and the filter construction of design D5; verify `tofu validate`.
- [x] 4.2 Add `check "public_exposure"` (public-read ACL, `Principal` `"*"` or `{AWS = "*"}` with `Allow`, CORS origin `"*"`) in `checks.tf` listed in the `main.tf` header; verify `tofu validate`.
- [x] 4.3 Add tests: expiration rule, rule without action, duplicate ids, tags with multipart, status `Paused`, and the check warnings (public-read, wildcard principal, wildcard origin) and the silent private case; verify `tofu test` reports the warnings via `expect_failures = [check.public_exposure]` where applicable.
- [x] 4.4 Add lifecycle rules (logs expiry, noncurrent version expiry, multipart abort) to `examples/complete`; verify `mise run test:examples`.

## 5. Documentation, security and release readiness

- [x] 5.1 Write `SECURITY.md` (what lands in state table: name, location, creation date, policy, CORS, lifecycle, `permissions` ids; why no objects or presigned URLs; credentials via `OSC_*`; encrypted state), `TESTING.md` (test table), README per terraform-repo-readme (title, badges, features, requirements, basic, complete and conditional-creation usage, security, Known Limitations incl. no tags and global bucket names, caller-side provider configuration, Releasing, `.terraform-docs.yml`); verify `pre-commit run -a` regenerates the terraform-docs block and passes.
- [x] 5.2 Apply `examples/complete` against a real Outscale account when one is available, confirm a second `plan` is empty (policy round-trip, set blocks, `AES256`), record the provider and example versions in the README compatibility table, and destroy; if skipped, state it explicitly and keep the tag at `0.x`.
- [x] 5.3 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`, `mise run test:examples`, `mise run spec-validate` and `pre-commit run -a`; verify all pass and report the output as-is.
- [ ] 5.4 Commit with a subject that reads as the CHANGELOG line (for example `Add OOS buckets with versioning, encryption, policy, CORS and lifecycle`), run `mise run changelog` at release and tag `v0.1.0` (annotated, on `main`).

## Workflow follow-up

- Archive the change (`/openspec-archive-change`) after review so `openspec/specs/module-contract` and `openspec/specs/buckets` become the current contract.
- Confirm the changelog subject and the terraform-docs README block before archiving.
