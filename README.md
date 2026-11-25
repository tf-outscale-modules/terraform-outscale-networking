# Outscale Object Storage Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Outscale Provider][provider-badge]][provider-url]
[![Latest Release][release-badge]][release-url]

Terraform module for provisioning Outscale Object Storage (OOS, S3-compatible) buckets and their settings with the official `outscale/outscale` provider.

## Features

- **Bucket map** - one entry per bucket, keyed by bucket name, with stable `for_each` addresses
- **Secure defaults** - versioning `Enabled`, `AES256` default encryption, private bucket, `force_delete = false`; each opt-out is explicit
- **Policy, CORS, lifecycle** - optional per bucket, validated at plan time
- **Plan-time warnings** - a `check` block flags `public-read` ACLs, `Principal "*"` allow statements and `*` CORS origins
- **Official provider only** - uses the `outscale_oos_*` resources of `outscale/outscale` 1.9.0+, not the `aws` provider

## Requirements

| Name | Version |
|------|---------|
| terraform / tofu | >= 1.11.0 |
| outscale | ~> 1.9 |

The module has no `provider {}` block. Configure the `outscale` provider in the root module: credentials and region through `OSC_ACCESS_KEY`, `OSC_SECRET_KEY` and `OSC_REGION` (or the provider arguments), and, only when the default does not fit, the OOS endpoint with `OSC_ENDPOINT_OOS` or `provider "outscale" { oos { endpoint = "..." } }`.

Compatibility: the complete example's shapes (3 buckets, policy, CORS, lifecycle, versioning, encryption opt-out; 11 resources) were applied on the OOS API of eu-west-2 with provider 1.9.0 on 2026-11-25, with an empty second plan and a clean destroy. The release stays in `0.x`.

## Usage

### Basic example

```hcl
module "oos" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/outscale-object-storage.git?ref=v0.1.0"

  buckets = {
    "mycompany-logs" = {} # private, versioned, AES256-encrypted
  }
}
```

### Complete example

See [examples/complete](examples/complete): policy, CORS, lifecycle rules, ACL, `force_delete`, versioning and encryption opt-outs.

```hcl
module "oos" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/outscale-object-storage.git?ref=v0.1.0"

  buckets = {
    "mycompany-assets" = {
      cors_rules = [{
        allowed_headers = ["Authorization"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["https://www.example.com"]
        max_age_seconds = 600
      }]
      lifecycle_rules = [{
        id                                 = "expire-old-versions"
        noncurrent_version_expiration_days = 30
      }]
    }
  }
}
```

### Conditional creation

`buckets = {}` (the default) creates nothing, and each setting is created only for the entries that use it:

```hcl
buckets = {
  "mycompany-a" = {}                                  # bucket + versioning + encryption
  "mycompany-b" = { enable_encryption = false }       # no encryption configuration
  "mycompany-c" = { policy = jsonencode({ ... }) }    # adds a bucket policy
}
```

## Security Considerations

See [SECURITY.md](SECURITY.md).

1. Credentials never belong in `.tf` files; use `OSC_*` environment variables or a vault.
2. The state holds bucket names, policies and rules, but no secret; keep it in an encrypted backend anyway.
3. Public exposure (`public-read`, `Principal "*"`, CORS `*`) is allowed but reported by a `check` warning; `public-read-write` is rejected.
4. Objects and presigned URLs are deliberately not managed, so no object content or signed URL lands in state.

## Known Limitations

1. `outscale_oos_bucket` has no `tags` argument, so buckets cannot be tagged.
2. Bucket names are one namespace per region; a name already taken fails at apply. Prefix your names.
3. Lifecycle expiry is asynchronous on the OOS side.
4. `aws:kms` currently behaves as `AES256`; the module always sends `AES256`.
5. Versioning is not retroactive for encryption: versions uploaded before encryption was enabled stay unencrypted.
6. The `check` block only recognises `Principal "*"` and `{ AWS = "*" }` in policies; other unsafe policy shapes are not detected.
7. The provider returns a null `location_name` on eu-west-2, so no location output exists.
8. Not managed in this release: objects, object copy, object retention, presigned URLs, `grant` and `object_lock`.
9. The provider's OOS resources are new (GA in 1.9.0); behaviour may change in 1.9.x patches.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_outscale"></a> [outscale](#requirement\_outscale) | ~> 1.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_outscale"></a> [outscale](#provider\_outscale) | ~> 1.9 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [outscale_oos_bucket.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket) | resource |
| [outscale_oos_bucket_cors.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket_cors) | resource |
| [outscale_oos_bucket_encryption.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket_encryption) | resource |
| [outscale_oos_bucket_lifecycle.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket_lifecycle) | resource |
| [outscale_oos_bucket_policy.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket_policy) | resource |
| [outscale_oos_bucket_versioning.this](https://registry.terraform.io/providers/outscale/outscale/latest/docs/resources/oos_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_buckets"></a> [buckets](#input\_buckets) | Map of OOS buckets to create, keyed by bucket name (3-63 characters of lowercase letters, digits and hyphens).<br/>The default {} creates nothing. Each entry accepts:<br/>- acl: canned ACL (private, public-read, authenticated-read); null sends nothing and keeps the server default (private).<br/>- force\_delete: when true, destroy first purges every object, version and delete marker; default false.<br/>- versioning\_status: Enabled (default) or Suspended.<br/>- enable\_encryption: default AES256 server-side encryption; default true, false is the explicit opt-out.<br/>- policy: bucket policy as a JSON string (use jsonencode); null creates no policy.<br/>- cors\_rules: list of CORS rules (allowed\_headers, allowed\_methods among GET/PUT/HEAD/POST/DELETE, allowed\_origins, optional expose\_headers, max\_age\_seconds >= 0).<br/>- lifecycle\_rules: list of rules with a unique id, status (Enabled default or Disabled), optional prefix and tags filter and at least one action among expiration\_days, expired\_object\_delete\_marker, noncurrent\_version\_expiration\_days and abort\_incomplete\_multipart\_upload\_days. expired\_object\_delete\_marker cannot be combined with expiration\_days in one rule. A rule using tags cannot set expired\_object\_delete\_marker or abort\_incomplete\_multipart\_upload\_days. | <pre>map(object({<br/>    acl               = optional(string)<br/>    force_delete      = optional(bool, false)<br/>    versioning_status = optional(string, "Enabled")<br/>    enable_encryption = optional(bool, true)<br/>    policy            = optional(string)<br/>    cors_rules = optional(list(object({<br/>      allowed_headers = set(string)<br/>      allowed_methods = set(string)<br/>      allowed_origins = set(string)<br/>      expose_headers  = optional(set(string))<br/>      max_age_seconds = number<br/>    })), [])<br/>    lifecycle_rules = optional(list(object({<br/>      id                                     = string<br/>      status                                 = optional(string, "Enabled")<br/>      prefix                                 = optional(string)<br/>      tags                                   = optional(map(string))<br/>      expiration_days                        = optional(number)<br/>      expired_object_delete_marker           = optional(bool)<br/>      noncurrent_version_expiration_days     = optional(number)<br/>      abort_incomplete_multipart_upload_days = optional(number)<br/>    })), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_ids"></a> [bucket\_ids](#output\_bucket\_ids) | Map of bucket key to bucket id (equal to the bucket name), usable as the bucket argument of other OOS resources. |
<!-- END_TF_DOCS -->

## Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Module overview and usage |
| [SECURITY.md](SECURITY.md) | Security guidance and what lands in state |
| [TESTING.md](TESTING.md) | Unit tests and how to run them |
| [CHANGELOG.md](CHANGELOG.md) | Version history (generated by git-cliff) |
| [examples/](examples) | Basic and complete examples |
| [openspec/](openspec) | Specs and planned changes |

## Contributing

1. Run `tofu fmt -recursive`, `tofu validate`, `tflint --recursive` and `tofu test` (or `pre-commit run -a`).
2. Update examples and documentation with every behaviour change.
3. Plan changes through OpenSpec (`openspec/`) and write the commit subject as its CHANGELOG line.

## Releasing

1. Merge to `main`, then run `mise run changelog` (git-cliff generates `CHANGELOG.md` from the commit subjects).
2. Tag `vX.Y.Z` (annotated) on `main`, equal to the version in the changelog heading, per semver (`0.x` until the contract is stable).
3. Update the `?ref=` pins in this README to the new tag.

## License

This project is licensed under the Apache License 2.0, see the [LICENSE](LICENSE) file for details.

## Disclaimer

This module is provided "as is", without warranty of any kind, express or implied. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.11-623CE4
[terraform-url]: https://www.terraform.io

[provider-badge]: https://img.shields.io/badge/Outscale%20Provider-~%3E1.9-blueviolet
[provider-url]: https://registry.terraform.io/providers/outscale/outscale/latest

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/outscale-object-storage?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/outscale-object-storage/-/releases
