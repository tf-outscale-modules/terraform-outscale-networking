################################################################################
# Buckets
################################################################################

variable "buckets" {
  description = <<-EOT
    Map of OOS buckets to create, keyed by bucket name (3-63 characters of lowercase letters, digits and hyphens).
    The default {} creates nothing. Each entry accepts:
    - acl: canned ACL (private, public-read, authenticated-read); null sends nothing and keeps the server default (private).
    - force_delete: when true, destroy first purges every object, version and delete marker; default false.
    - versioning_status: Enabled (default) or Suspended.
    - enable_encryption: default AES256 server-side encryption; default true, false is the explicit opt-out.
    - policy: bucket policy as a JSON string (use jsonencode); null creates no policy.
    - cors_rules: list of CORS rules (allowed_headers, allowed_methods among GET/PUT/HEAD/POST/DELETE, allowed_origins, optional expose_headers, max_age_seconds >= 0).
    - lifecycle_rules: list of rules with a unique id, status (Enabled default or Disabled), optional prefix and tags filter and at least one action among expiration_days, expired_object_delete_marker, noncurrent_version_expiration_days and abort_incomplete_multipart_upload_days. expired_object_delete_marker cannot be combined with expiration_days in one rule. A rule using tags cannot set expired_object_delete_marker or abort_incomplete_multipart_upload_days.
  EOT
  type = map(object({
    acl               = optional(string)
    force_delete      = optional(bool, false)
    versioning_status = optional(string, "Enabled")
    enable_encryption = optional(bool, true)
    policy            = optional(string)
    cors_rules = optional(list(object({
      allowed_headers = set(string)
      allowed_methods = set(string)
      allowed_origins = set(string)
      expose_headers  = optional(set(string))
      max_age_seconds = number
    })), [])
    lifecycle_rules = optional(list(object({
      id                                     = string
      status                                 = optional(string, "Enabled")
      prefix                                 = optional(string)
      tags                                   = optional(map(string))
      expiration_days                        = optional(number)
      expired_object_delete_marker           = optional(bool)
      noncurrent_version_expiration_days     = optional(number)
      abort_incomplete_multipart_upload_days = optional(number)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, _ in var.buckets : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", name))
    ])
    error_message = "Bucket names must be 3-63 characters of lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }

  validation {
    condition = alltrue([
      for _, b in var.buckets : b.acl == null ? true : contains(["private", "public-read", "authenticated-read"], b.acl)
    ])
    error_message = "acl must be one of private, public-read, authenticated-read."
  }

  validation {
    condition = alltrue([
      for _, b in var.buckets : contains(["Enabled", "Suspended"], b.versioning_status)
    ])
    error_message = "versioning_status must be one of Enabled, Suspended."
  }

  validation {
    condition = alltrue([
      for _, b in var.buckets : b.policy == null ? true : can(jsondecode(b.policy))
    ])
    error_message = "policy must be a valid JSON document."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [
        for r in b.cors_rules : [
          for m in r.allowed_methods : contains(["GET", "PUT", "HEAD", "POST", "DELETE"], m)
        ]
      ]
    ]))
    error_message = "allowed_methods must be among GET, PUT, HEAD, POST, DELETE."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [for r in b.cors_rules : r.max_age_seconds >= 0]
    ]))
    error_message = "max_age_seconds must be zero or greater."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [for r in b.lifecycle_rules : contains(["Enabled", "Disabled"], r.status)]
    ]))
    error_message = "Lifecycle rule status must be Enabled or Disabled."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [
        for r in b.lifecycle_rules : (
          r.expiration_days != null ||
          r.expired_object_delete_marker == true ||
          r.noncurrent_version_expiration_days != null ||
          r.abort_incomplete_multipart_upload_days != null
        )
      ]
    ]))
    error_message = "Each lifecycle rule needs at least one action: expiration_days, expired_object_delete_marker, noncurrent_version_expiration_days or abort_incomplete_multipart_upload_days."
  }

  validation {
    condition = alltrue([
      for _, b in var.buckets : length(distinct([for r in b.lifecycle_rules : r.id])) == length(b.lifecycle_rules)
    ])
    error_message = "Lifecycle rule ids must be unique within a bucket."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [
        for r in b.lifecycle_rules : !(r.expiration_days != null && r.expired_object_delete_marker == true)
      ]
    ]))
    error_message = "A lifecycle rule cannot set both expiration_days and expired_object_delete_marker; use two rules."
  }

  validation {
    condition = alltrue(flatten([
      for _, b in var.buckets : [
        for r in b.lifecycle_rules : (
          (r.tags == null ? 0 : length(r.tags)) == 0 ||
          (r.expired_object_delete_marker != true && r.abort_incomplete_multipart_upload_days == null)
        )
      ]
    ]))
    error_message = "A lifecycle rule using tags cannot set expired_object_delete_marker or abort_incomplete_multipart_upload_days."
  }
}
