locals {
  # Policies are re-encoded so key order and whitespace match across plans.
  policies = {
    for name, b in var.buckets : name => jsonencode(jsondecode(b.policy)) if b.policy != null
  }

  cors_rules = {
    for name, b in var.buckets : name => b.cors_rules if length(b.cors_rules) > 0
  }

  # One object shape for every rule: the provider needs `filter.and` only when
  # tags are used and `filter.prefix` otherwise.
  lifecycle_rules = {
    for name, b in var.buckets : name => [
      for r in b.lifecycle_rules : {
        id     = r.id
        status = r.status
        filter = {
          prefix = (r.tags == null ? 0 : length(r.tags)) > 0 ? null : r.prefix
          and = (r.tags == null ? 0 : length(r.tags)) > 0 ? {
            prefix = r.prefix == null ? "" : r.prefix
            tags   = r.tags
          } : null
        }
        expiration = r.expiration_days != null || r.expired_object_delete_marker == true ? {
          days                         = r.expiration_days
          expired_object_delete_marker = r.expired_object_delete_marker
        } : null
        noncurrent_version_expiration = r.noncurrent_version_expiration_days == null ? null : {
          noncurrent_days = r.noncurrent_version_expiration_days
        }
        abort_incomplete_multipart_upload = r.abort_incomplete_multipart_upload_days == null ? null : {
          days_after_initiation = r.abort_incomplete_multipart_upload_days
        }
      }
    ] if length(b.lifecycle_rules) > 0
  }

  # Inputs of the public_exposure check (checks.tf).
  public_acl_buckets = sort([for name, b in var.buckets : name if b.acl == "public-read"])

  open_policy_buckets = sort([
    for name, p in local.policies : name if anytrue([
      for s in flatten([jsondecode(p).Statement]) : try(
        s.Effect == "Allow" && anytrue([for a in flatten([try(s.Principal.AWS, s.Principal)]) : a == "*"]),
        false
      )
    ])
  ])

  wildcard_cors_buckets = sort([
    for name, rules in local.cors_rules : name if anytrue(flatten([
      for r in rules : [for o in r.allowed_origins : o == "*"]
    ]))
  ])
}
