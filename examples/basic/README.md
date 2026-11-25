# Basic example

One private OOS bucket with the secure defaults (versioning `Enabled`, `AES256` encryption).

Prerequisites: an Outscale account and access keys, exported as `OSC_ACCESS_KEY`, `OSC_SECRET_KEY` and `OSC_REGION` (optionally `OSC_ENDPOINT_OOS`). Never write them in `.tf` files.

```bash
tofu init
tofu plan -var 'bucket_name=mycompany-basic-example'
```

`tofu apply` and `tofu destroy` create and remove a real bucket; run them only against an account you own.
