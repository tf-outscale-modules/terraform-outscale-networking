################################################################################
# OOS buckets (outscale provider >= 1.9.0)
#
# main.tf   - bucket and its per-bucket settings
# locals.tf - filtered for_each maps and check inputs
# checks.tf - plan-time warnings for public exposure
################################################################################

resource "outscale_oos_bucket" "this" {
  for_each = var.buckets

  name         = each.key
  acl          = each.value.acl
  force_delete = each.value.force_delete
}

resource "outscale_oos_bucket_versioning" "this" {
  for_each = var.buckets

  bucket = outscale_oos_bucket.this[each.key].id
  status = each.value.versioning_status
}

resource "outscale_oos_bucket_encryption" "this" {
  for_each = { for name, b in var.buckets : name => b if b.enable_encryption }

  bucket          = outscale_oos_bucket.this[each.key].id
  encryption_type = "AES256"
}

resource "outscale_oos_bucket_policy" "this" {
  for_each = local.policies

  bucket = outscale_oos_bucket.this[each.key].id
  policy = each.value
}

resource "outscale_oos_bucket_cors" "this" {
  for_each = local.cors_rules

  bucket = outscale_oos_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value

    content {
      allowed_headers = rule.value.allowed_headers
      allowed_methods = rule.value.allowed_methods
      allowed_origins = rule.value.allowed_origins
      expose_headers  = rule.value.expose_headers
      max_age_seconds = rule.value.max_age_seconds
    }
  }
}

resource "outscale_oos_bucket_lifecycle" "this" {
  for_each = local.lifecycle_rules

  bucket = outscale_oos_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value

    content {
      id                                = rule.value.id
      status                            = rule.value.status
      filter                            = rule.value.filter
      expiration                        = rule.value.expiration
      noncurrent_version_expiration     = rule.value.noncurrent_version_expiration
      abort_incomplete_multipart_upload = rule.value.abort_incomplete_multipart_upload
    }
  }

  # Lifecycle rules for noncurrent versions need the versioning state first.
  depends_on = [outscale_oos_bucket_versioning.this]
}
