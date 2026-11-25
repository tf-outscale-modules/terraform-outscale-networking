# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-11-25
- Add OOS buckets with versioning, encryption, policy, CORS and lifecycle

Add the first release of the module: a `buckets` map creating Outscale
Object Storage buckets with the `outscale_oos_*` resources of the
outscale/outscale provider (~> 1.9, required_version >= 1.11.0).

Each bucket gets versioning (Enabled by default) and AES256 default
encryption (opt out with enable_encryption = false), plus optional
policy, CORS rules and lifecycle rules, all validated at plan time. A
check block warns on public-read ACLs, Principal "*" policies and
wildcard CORS origins; public-read-write is rejected. Output:
bucket_ids.

Also adds the repository scaffold (template files, CI, mise, agent
skills), unit tests, basic and complete examples, SECURITY.md and
TESTING.md, and the archived OpenSpec change with its main specs.
Verified against a real account: empty second plan and clean destroy.
- Initial commit

