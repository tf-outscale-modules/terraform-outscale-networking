variable "bucket_name" {
  description = "Name of the bucket: 3-63 characters of lowercase letters, digits and hyphens. Bucket names are shared by every OOS user of the region, so prefix it (for example with your company name)."
  type        = string
}
