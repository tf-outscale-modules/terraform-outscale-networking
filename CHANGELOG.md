# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-02-07
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

