################################################################################
# Complete Example - outscale-object-storage
# Exercises every input: ACL, force_delete, versioning, encryption opt-out,
# policy, CORS and lifecycle rules.
################################################################################

locals {
  logs_bucket   = "${var.bucket_prefix}-logs"
  assets_bucket = "${var.bucket_prefix}-assets"
  scratch       = "${var.bucket_prefix}-scratch"
}

module "oos" {
  source = "../../"

  buckets = {
    # Versioned, encrypted log bucket with expiry and a read-only policy for one account.
    (local.logs_bucket) = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "ReadLogs"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::${var.reader_account_id}:root" }
          Action    = ["s3:GetObject", "s3:ListBucket"]
          Resource = [
            "arn:aws:s3:::${local.logs_bucket}",
            "arn:aws:s3:::${local.logs_bucket}/*",
          ]
        }]
      })

      lifecycle_rules = [
        {
          id              = "expire-logs"
          prefix          = "logs/"
          expiration_days = 90
        },
        {
          id                                 = "expire-old-versions"
          noncurrent_version_expiration_days = 30
        },
        {
          id                                     = "abort-multipart"
          abort_incomplete_multipart_upload_days = 7
        },
        {
          id              = "expire-tmp-tagged"
          status          = "Disabled"
          tags            = { class = "tmp" }
          expiration_days = 7
        },
      ]
    }

    # Assets read from a browser: CORS limited to one origin, ACL stays private.
    (local.assets_bucket) = {
      cors_rules = [
        {
          allowed_headers = ["Authorization", "Content-Type"]
          allowed_methods = ["GET", "HEAD"]
          allowed_origins = [var.allowed_origin]
          expose_headers  = ["ETag"]
          max_age_seconds = 600
        },
      ]
    }

    # Disposable bucket: versioning suspended, no default encryption, purge on destroy.
    (local.scratch) = {
      acl               = "private"
      force_delete      = true
      versioning_status = "Suspended"
      enable_encryption = false
    }
  }
}
