## 1. Code

- [x] 1.1 Validations on `route_tables` (one target, Internet Service enabled); description update
- [x] 1.2 `checks.tf` with the NAT and no-target warnings; `enable_nat_services` description update

## 2. Documentation and tests

- [x] 2.1 README: `source` and Conditional Creation wording
- [x] 2.2 Tests: one rejected run per validation, one run per check, happy path
- [x] 2.3 No example input changes
- [x] 2.4 `tofu fmt`, `tofu validate`, `tofu test`, `tflint`, `pre-commit run -a`, `openspec validate --all --strict`
