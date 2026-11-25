# Testing

The unit suite uses OpenTofu's native test framework in plan mode with a mock `outscale` provider: no credentials, no server, no cost.

```bash
tofu init -backend=false
tofu test            # or: mise run test
mise run test:examples   # init + validate every example
```

## What's tested

| Test | Description |
|------|-------------|
| `empty_call` | No resource and empty outputs without `buckets` |
| `minimal_entry` | Defaults: name from key, no ACL, versioning `Enabled`, `AES256`, no policy/CORS/lifecycle |
| `two_buckets_and_outputs` | Two buckets, outputs keyed like the input |
| `rejects_uppercase_name`, `rejects_short_name`, `rejects_trailing_hyphen` | Bucket name validation |
| `rejects_public_read_write` | ACL validation |
| `versioning_suspended`, `rejects_versioning_status` | Versioning status |
| `encryption_opt_out_is_per_bucket` | `enable_encryption = false` affects only its bucket |
| `valid_policy_is_normalised`, `rejects_invalid_policy` | Policy JSON re-encoding and validation |
| `two_cors_rules`, `rejects_cors_method`, `rejects_negative_max_age` | CORS rules |
| `lifecycle_expiration_rule`, `rejects_rule_without_action`, `rejects_duplicate_rule_ids`, `rejects_delete_marker_with_expiration_days`, `delete_marker_rule_alone`, `rejects_tags_with_multipart`, `rejects_rule_status` | Lifecycle rules |
| `private_bucket_no_warning`, `warns_public_read`, `warns_everyone_principal`, `warns_wildcard_cors_origin` | `check "public_exposure"` |

## Not covered

No `command = apply` fixture exists. Before a release, apply `examples/complete` against a real Outscale account you own, confirm the second `plan` is empty, then destroy, and record the result in the README compatibility note.
