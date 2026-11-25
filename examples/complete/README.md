# Complete example

Three buckets that use every input of the module: a policy and lifecycle rules on a log bucket, a CORS rule on an assets bucket, and a disposable bucket with versioning suspended, no default encryption and `force_delete`.

Prerequisites: an Outscale account and access keys, exported as `OSC_ACCESS_KEY`, `OSC_SECRET_KEY` and `OSC_REGION` (optionally `OSC_ENDPOINT_OOS`). Never write them in `.tf` files.

```bash
tofu init
tofu plan \
  -var 'bucket_prefix=mycompany-example' \
  -var 'reader_account_id=123456789012' \
  -var 'allowed_origin=https://www.example.com'
```

`tofu apply` and `tofu destroy` create and remove real buckets; run them only against an account you own.
