output "bucket_ids" {
  description = "Map of bucket key to bucket id (equal to the bucket name), usable as the bucket argument of other OOS resources."
  value       = { for name, b in outscale_oos_bucket.this : name => b.id }
}
