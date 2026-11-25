variable "bucket_prefix" {
  description = "Prefix of the three bucket names (lowercase letters, digits and hyphens). Bucket names are shared by every OOS user of the region, so use something unique to you."
  type        = string
}

variable "reader_account_id" {
  description = "12-digit Outscale account id allowed to read the log bucket through the bucket policy."
  type        = string
}

variable "allowed_origin" {
  description = "Browser origin allowed by the CORS rule of the assets bucket, for example https://www.example.com."
  type        = string
}
