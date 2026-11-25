################################################################################
# Basic Example - outscale-object-storage
# One private bucket with the secure defaults: versioning Enabled and AES256
# encryption.
################################################################################

module "oos" {
  source = "../../"

  buckets = {
    (var.bucket_name) = {}
  }
}
