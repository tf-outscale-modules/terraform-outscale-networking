## 1. Inputs and validations (`variables.tf`)

- [x] 1.1 Add `secured_cookies` (`optional(bool)`), `public_ip_key` (`optional(string)`) and `subregion_names` (`optional(list(string))`) to `load_balancers`, defaults `null`; update the description (replacement on `subregion_names`, no revert on removal) per `terraform-variables`
- [x] 1.2 Add `validation` blocks to `load_balancers`: `subnet_keys` and `subregion_names` mutually exclusive; `public_ip_key` only with `internet-facing`; `public_ip_key` is a key of `var.public_ips`; messages name the accepted values
- [x] 1.3 Add `source_net_account_id` (`optional(string)`, default `null`) to `net_peerings` with a `^[0-9]{12}$` validation; state in the description that the accepter side in another account is outside the module and `auto_accept` is same-account only

## 2. Resources

- [x] 2.1 `services.tf`: set `secured_cookies`, `public_ip` (`each.value.public_ip_key == null ? null : outscale_public_ip.this[each.value.public_ip_key].public_ip`) and `subregion_names` on `outscale_load_balancer.this`; `subnets = length(each.value.subnet_keys) > 0 ? [...] : null`
- [x] 2.2 `connectivity.tf`: set `source_net_account_id` on `outscale_net_peering.this`
- [x] 2.3 Confirm with `tofu plan` on `examples/complete` that existing resources show no diff (empty second plan); no apply against a real account unless requested, and say so

## 3. Tests (`tests/main.tftest.hcl`)

- [x] 3.1 Plan-mode runs: load balancer with `secured_cookies = true`; Subregion load balancer (`subnet_keys = []`, `subregion_names`); fixed public IP via `public_ip_key` (plan succeeds; the address is unknown at plan, assert resource count and absence of errors); cross-account peering with `source_net_account_id`
- [x] 3.2 `expect_failures` runs: `subnet_keys` with `subregion_names`; `public_ip_key` on an `internal` load balancer; `public_ip_key` naming no `public_ips` key; malformed `source_net_account_id`
- [x] 3.3 Regression run: an entry without the new attributes plans exactly the previous arguments

## 4. Examples and docs

- [x] 4.1 Update `examples/complete`: a load balancer with `secured_cookies` and `public_ip_key` pointing at a `public_ips` entry, and a commented cross-account peering showing `source_net_account_id` and the accepter-side note; check `examples/basic` is unaffected
- [x] 4.2 README: note the accepter-side limit and replacement behaviour outside the `BEGIN_TF_DOCS`/`END_TF_DOCS` block; regenerate the block with terraform-docs (never edit it by hand); no `SECURITY.md` change (no secret, no new state content)

## 5. Verification and delivery

- [x] 5.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a`, `mise run spec-validate`; report output as-is
- [x] 5.2 Commit subject that reads as the CHANGELOG line, e.g. `Add load balancer secure cookies, fixed public IP and Subregions, and cross-account peering source account` (git-cliff generates `CHANGELOG.md`); release is a minor bump; merge request notes the replacement on `subregion_names` and `source_net_account_id`
