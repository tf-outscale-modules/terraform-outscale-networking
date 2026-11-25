# Plan-mode unit tests: the mock provider needs no credentials or server.
mock_provider "outscale" {}

run "empty_call" {
  command = plan

  assert {
    condition     = length(outscale_oos_bucket.this) == 0 && length(outscale_oos_bucket_versioning.this) == 0 && length(output.bucket_ids) == 0
    error_message = "No resource and empty outputs expected without buckets"
  }
}

run "minimal_entry" {
  command = plan

  variables {
    buckets = { "acme-logs" = {} }
  }

  assert {
    condition     = outscale_oos_bucket.this["acme-logs"].name == "acme-logs" && outscale_oos_bucket.this["acme-logs"].acl == null && outscale_oos_bucket.this["acme-logs"].force_delete == false
    error_message = "Bucket must be named after its key with no ACL and force_delete false"
  }

  assert {
    condition     = outscale_oos_bucket_versioning.this["acme-logs"].status == "Enabled"
    error_message = "Versioning must default to Enabled"
  }

  assert {
    condition     = outscale_oos_bucket_encryption.this["acme-logs"].encryption_type == "AES256"
    error_message = "Encryption must default to AES256"
  }

  assert {
    condition     = length(outscale_oos_bucket_policy.this) == 0 && length(outscale_oos_bucket_cors.this) == 0 && length(outscale_oos_bucket_lifecycle.this) == 0
    error_message = "Policy, CORS and lifecycle must not exist by default"
  }
}

run "two_buckets_and_outputs" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {}
      "acme-data" = { acl = "private" }
    }
  }

  assert {
    condition     = length(outscale_oos_bucket.this) == 2 && length(output.bucket_ids) == 2
    error_message = "Both buckets and both output keys expected"
  }
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    buckets = { "Acme_Logs" = {} }
  }

  expect_failures = [var.buckets]
}

run "rejects_short_name" {
  command = plan

  variables {
    buckets = { "ab" = {} }
  }

  expect_failures = [var.buckets]
}

run "rejects_trailing_hyphen" {
  command = plan

  variables {
    buckets = { "acme-" = {} }
  }

  expect_failures = [var.buckets]
}

run "rejects_public_read_write" {
  command = plan

  variables {
    buckets = { "acme-logs" = { acl = "public-read-write" } }
  }

  expect_failures = [var.buckets]
}

run "versioning_suspended" {
  command = plan

  variables {
    buckets = { "acme-logs" = { versioning_status = "Suspended" } }
  }

  assert {
    condition     = outscale_oos_bucket_versioning.this["acme-logs"].status == "Suspended"
    error_message = "Versioning must be Suspended"
  }
}

run "rejects_versioning_status" {
  command = plan

  variables {
    buckets = { "acme-logs" = { versioning_status = "Disabled" } }
  }

  expect_failures = [var.buckets]
}

run "encryption_opt_out_is_per_bucket" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = { enable_encryption = false }
      "acme-data" = {}
    }
  }

  assert {
    condition     = !contains(keys(outscale_oos_bucket_encryption.this), "acme-logs") && contains(keys(outscale_oos_bucket_encryption.this), "acme-data")
    error_message = "Only the opted-out bucket must lose its encryption configuration"
  }
}

run "valid_policy_is_normalised" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        policy = <<-EOT
          {"Statement": [{"Resource": "arn:aws:s3:::acme-logs/*", "Action": "s3:GetObject", "Effect": "Deny", "Principal": "*"}], "Version": "2012-10-17"}
        EOT
      }
    }
  }

  assert {
    condition     = outscale_oos_bucket_policy.this["acme-logs"].policy == jsonencode(jsondecode(var.buckets["acme-logs"].policy))
    error_message = "Policy must be re-encoded canonically"
  }
}

run "rejects_invalid_policy" {
  command = plan

  variables {
    buckets = { "acme-logs" = { policy = "not json" } }
  }

  expect_failures = [var.buckets]
}

run "two_cors_rules" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        cors_rules = [
          {
            allowed_headers = ["Authorization"]
            allowed_methods = ["GET", "PUT"]
            allowed_origins = ["https://www.example.com"]
            expose_headers  = ["ETag"]
            max_age_seconds = 600
          },
          {
            allowed_headers = ["*"]
            allowed_methods = ["HEAD"]
            allowed_origins = ["https://www.example.org"]
            max_age_seconds = 0
          },
        ]
      }
    }
  }

  assert {
    condition     = length(outscale_oos_bucket_cors.this) == 1 && length(outscale_oos_bucket_cors.this["acme-logs"].rule) == 2
    error_message = "One CORS configuration with two rules expected"
  }
}

run "rejects_cors_method" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        cors_rules = [{
          allowed_headers = ["*"]
          allowed_methods = ["PATCH"]
          allowed_origins = ["https://www.example.com"]
          max_age_seconds = 60
        }]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_negative_max_age" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        cors_rules = [{
          allowed_headers = ["*"]
          allowed_methods = ["GET"]
          allowed_origins = ["https://www.example.com"]
          max_age_seconds = -1
        }]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "lifecycle_expiration_rule" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        lifecycle_rules = [
          { id = "logs", prefix = "logs/", expiration_days = 90 },
          { id = "tagged", tags = { class = "tmp" }, expiration_days = 7, noncurrent_version_expiration_days = 30 },
          { id = "multipart", abort_incomplete_multipart_upload_days = 3 },
        ]
      }
    }
  }

  assert {
    condition     = length(outscale_oos_bucket_lifecycle.this["acme-logs"].rule) == 3
    error_message = "Three lifecycle rules expected"
  }
}

run "rejects_rule_without_action" {
  command = plan

  variables {
    buckets = { "acme-logs" = { lifecycle_rules = [{ id = "logs", prefix = "logs/" }] } }
  }

  expect_failures = [var.buckets]
}

run "rejects_duplicate_rule_ids" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        lifecycle_rules = [
          { id = "logs", expiration_days = 1 },
          { id = "logs", expiration_days = 2 },
        ]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_tags_with_multipart" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        lifecycle_rules = [{ id = "x", tags = { a = "b" }, abort_incomplete_multipart_upload_days = 3 }]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "rejects_delete_marker_with_expiration_days" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        lifecycle_rules = [{ id = "x", expiration_days = 5, expired_object_delete_marker = true }]
      }
    }
  }

  expect_failures = [var.buckets]
}

run "delete_marker_rule_alone" {
  command = plan

  variables {
    buckets = {
      "acme-logs" = {
        lifecycle_rules = [{ id = "x", prefix = "combo/", expired_object_delete_marker = true }]
      }
    }
  }

  assert {
    condition     = length(outscale_oos_bucket_lifecycle.this["acme-logs"].rule) == 1
    error_message = "A delete-marker-only rule must be accepted"
  }
}

run "rejects_rule_status" {
  command = plan

  variables {
    buckets = { "acme-logs" = { lifecycle_rules = [{ id = "x", status = "Paused", expiration_days = 1 }] } }
  }

  expect_failures = [var.buckets]
}

run "private_bucket_no_warning" {
  command = plan

  variables {
    buckets = { "acme-logs" = { acl = "private" } }
  }
}

run "warns_public_read" {
  command = plan

  variables {
    buckets = { "acme-site" = { acl = "public-read" } }
  }

  expect_failures = [check.public_exposure]
}

run "warns_everyone_principal" {
  command = plan

  variables {
    buckets = {
      "acme-site" = {
        policy = jsonencode({
          Version   = "2012-10-17"
          Statement = [{ Effect = "Allow", Principal = { AWS = "*" }, Action = "s3:GetObject", Resource = "arn:aws:s3:::acme-site/*" }]
        })
      }
    }
  }

  expect_failures = [check.public_exposure]
}

run "warns_wildcard_cors_origin" {
  command = plan

  variables {
    buckets = {
      "acme-site" = {
        cors_rules = [{
          allowed_headers = ["*"]
          allowed_methods = ["GET"]
          allowed_origins = ["*"]
          max_age_seconds = 60
        }]
      }
    }
  }

  expect_failures = [check.public_exposure]
}
