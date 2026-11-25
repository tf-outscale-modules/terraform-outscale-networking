# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-11-25
- Add load balancer secure cookies, fixed public IP and Subregions, and cross-account peering source account

load_balancers accepts secured_cookies, public_ip_key (a key of
public_ips, internet-facing only) and subregion_names (outside a Net,
exclusive with subnet_keys). net_peerings accepts source_net_account_id
(12-digit account id) for cross-account peerings; the accepter account
must accept the peering itself. All inputs default to null, so existing
callers see no diff. Load balancers without subnet_keys now send no
subnets instead of an empty list so that subregion_names does not
conflict. Changing subregion_names or source_net_account_id replaces the
resource. Verified with a live apply and an empty second plan; the
provider pin stays ~> 1.8.
- Validate route targets and warn on NAT without Internet Service

route_tables rejects a route with several target types and
use_internet_service while enable_internet_service is false. Checks
warn on a NAT service without an Internet Service and on a route with
no target. The README source and Conditional Creation text are
corrected. No upgrade action.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Move from Agent OS to OpenSpec and publish the baseline specs

Planning moves from Agent OS to OpenSpec: agent-os/ is removed and the
engineering standards now come from the quality, repository and terraform
OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict.

CI: mise 2026.10.17 resolves tools through mise-versions.jdx.dev instead of
the rate-limited api.github.com, and the pre-commit caches are keyed on the
toolchain files instead of the branch, so a toolchain change starts a fresh
cache. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- ci: fix the tag release pipeline

- create:release: install the git-cliff release binary (as in
  outscale-iam) instead of mise: the job runs under /bin/sh, where the
  bash-only `mise activate` output failed ("export: illegal option -a").
- Cache keys follow mise.toml / .pre-commit-config.yaml instead of the
  ref, so branches and tags share one cache instead of each leaving its
  own copy on the runner disk.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- chore(deps): upgrade outscale provider to ~> 1.8

- Bump the outscale provider constraint to ~> 1.8 (module and examples).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Removes unnecessary dependency

Removes the explicit dependency between the DHCP option and the Net. This is unnecessary, as the DHCP option does not need to be explicitly destroyed before the Net.
- Improves readability of Outscale description

Adds quotes to the Outscale description to clarify its content.
- Adds Terraform module standards and gotchas

Adds documentation for Terraform module patterns, focusing on key-based references, feature flags, route splitting, and self-referencing internet services.

Also documents common Outscale provider gotchas, including single-subnet load balancers, peering owner IDs, DHCP destroy races, and server certificate requirements for HTTPS listeners.
- Adds name tag to the Net resource

Adds a name tag to the Net resource for better identification and organization.

This change introduces a 'name' variable to the module, which is then used to tag the Net resource. This allows users to easily identify their Nets in the Outscale console and when using the API.
The name tag is applied using the common tags mechanism.
- Adds DHCP option dependency on Net

Ensures that the DHCP option is destroyed before the Net resource.
This prevents provider errors related to unlinking the DHCP option
after the Net resource has already been destroyed.
- Simplifies net peering example

Comments out the net peering example and adds instructions to replace placeholder values.
This prevents errors during initial deployment if the example values are not updated.
- Adds support for cross-account net peering

This change introduces the `accepter_owner_id` attribute
to the net peering configuration, which is necessary
for establishing net peering connections across
different Outscale accounts.

Additionally, it updates the documentation to reflect
Outscale's limitation of one subnet per load balancer.
- Removes trailing whitespace

Removes an unnecessary empty line at the end of the file.
- Adds Outscale Networking Terraform module

This commit introduces a new Terraform module for managing Outscale networking resources.

The module provides functionality for creating and managing core networking components, including Nets, subnets, DHCP options, connectivity resources like Internet Services and NAT services, routing with route tables, and services like load balancers and NICs.

It also incorporates Agent OS standards and tooling, and provides basic and complete examples, along with automated tests.
- Adds AgentOS command structure and standards

Introduces a framework for defining and enforcing coding standards and best practices across a codebase.

This includes:
- New commands for discovering, indexing, and injecting standards.
- Standard documentation, security guidelines, versioning, and code style.
- Guidelines for product planning and spec shaping.

The goal is to facilitate knowledge sharing, improve code consistency, and streamline development workflows within the AgentOS.
- Adds a standard .gitignore file

Adds a standard .gitignore file to exclude common files and directories that should not be tracked by Git.

This helps to keep the repository clean and prevents accidental commits of sensitive or unnecessary files, such as Terraform state files, secrets, OS-specific files, IDE-related files, and temporary files.
- Initial commit

