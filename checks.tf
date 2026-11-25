# Plan-time warnings for legal but risky exposure (terraform-security: guardrails).
check "public_exposure" {
  assert {
    condition     = length(local.public_acl_buckets) == 0
    error_message = "Objects of these buckets are readable by anyone (acl = public-read): ${join(", ", local.public_acl_buckets)}."
  }

  assert {
    condition     = length(local.open_policy_buckets) == 0
    error_message = "These buckets have a policy statement that allows Principal \"*\": ${join(", ", local.open_policy_buckets)}."
  }

  assert {
    condition     = length(local.wildcard_cors_buckets) == 0
    error_message = "These buckets have a CORS rule that allows the origin \"*\": ${join(", ", local.wildcard_cors_buckets)}."
  }
}
