# Security

## Reporting Security Issues

Do not open a public issue for a vulnerability. Contact the maintainers directly with the steps to reproduce and allow reasonable time for a fix before disclosure.

## What lands in state

The module has no secret-bearing input, so no write-only argument is needed.

| Value | In state | Sensitive | Mitigation |
|-------|----------|-----------|------------|
| Bucket name, `creation_date` | yes | no | Not secret |
| `acl`, `force_delete`, versioning status, encryption type | yes | no | Not secret |
| Bucket policy JSON | yes | no | Contains account ids and ARNs; keep state access restricted |
| CORS and lifecycle rule contents | yes | no | Not secret |
| `permissions` (owner and grantee S3 user ids, display names) | yes, computed | no | Identifiers, not credentials; encrypted state |
| Outscale access key and secret key | no | n/a | Held by the caller's provider configuration (`OSC_*`), never by the module |
| Objects and presigned URLs | no | n/a | Not managed: a presigned URL embeds a signature that acts as a bearer credential until it expires |

## Outscale API Credentials

- Set `OSC_ACCESS_KEY` and `OSC_SECRET_KEY` (provider 1.6+; the legacy `OUTSCALE_*` names are gone) as environment variables, never in `.tf` files.
- Use `mise.local.toml` (gitignored) for local credentials; in CI use masked, protected variables.
- Use separate access keys per environment with the least privilege the plan needs.

## Safe defaults and opt-outs

- Versioning is `Enabled`, default encryption `AES256` is on and the bucket ACL is the server default (private).
- `enable_encryption = false`, `versioning_status = "Suspended"` and `force_delete = true` are visible, deliberate opt-outs; review them in the plan.
- `public-read-write` is rejected. `public-read`, a policy allowing `Principal "*"` and a CORS origin `*` produce a plan-time warning (`check "public_exposure"`), not a failure.
- Write bucket policies with named principals and listed actions, never `*` on `*`.

## State Encryption

- Always use an encrypted remote backend and restrict access to the state.
- Never commit `.tfstate` files.
