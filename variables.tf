################################################################################
# Required Variables
################################################################################

variable "ip_range" {
  description = "The IP range for the Net, in CIDR notation (e.g., '10.0.0.0/16')"
  type        = string

  validation {
    condition     = can(cidrhost(var.ip_range, 0))
    error_message = "The ip_range must be a valid CIDR block (e.g., '10.0.0.0/16')."
  }
}

variable "subnets" {
  description = "Map of subnet definitions. Each key is a logical name, each value defines the subnet's CIDR and subregion."
  type = map(object({
    ip_range       = string
    subregion_name = string
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }
}

################################################################################
# Optional — Core
################################################################################

variable "name" {
  description = "Name tag for the Net"
  type        = string
  default     = null
}

variable "tenancy" {
  description = "The tenancy of VMs launched in the Net ('default' or 'dedicated')"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.tenancy)
    error_message = "Tenancy must be 'default' or 'dedicated'."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources that support tagging"
  type        = map(string)
  default     = {}
}

variable "dhcp_domain_name" {
  description = "The domain name for the DHCP options set (e.g., 'example.com')"
  type        = string
  default     = null
}

variable "dhcp_domain_name_servers" {
  description = "List of DNS server IPs for the DHCP options set"
  type        = list(string)
  default     = null
}

variable "dhcp_ntp_servers" {
  description = "List of NTP server IPs for the DHCP options set"
  type        = list(string)
  default     = null
}

variable "dhcp_log_servers" {
  description = "List of log server IPs for the DHCP options set"
  type        = list(string)
  default     = null
}

################################################################################
# Optional — Connectivity
################################################################################

variable "enable_internet_service" {
  description = "Whether to create an Internet Service and attach it to the Net"
  type        = bool
  default     = false
}

variable "enable_nat_services" {
  description = "Whether to create NAT services (expects enable_internet_service = true, otherwise a warning is raised)"
  type        = bool
  default     = false
}

variable "nat_services" {
  description = "Map of NAT service definitions. Each key is a logical name, subnet_key references a key in the subnets variable. A Public IP is auto-created for each NAT service."
  type = map(object({
    subnet_key = string
  }))
  default = {}
}

variable "public_ips" {
  description = "Map of standalone Public IP (Elastic IP) definitions"
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "enable_net_peerings" {
  description = "Whether to create Net peering connections"
  type        = bool
  default     = false
}

variable "net_peerings" {
  description = "Map of Net peering definitions. accepter_net_id is the ID of the remote Net. accepter_owner_id is required for cross-account peerings, together with source_net_account_id (the 12-digit account that owns this module's Net); changing source_net_account_id replaces the peering. Set auto_accept to true to automatically accept the peering (only works for same-account peerings). The accepter side of a cross-account peering belongs to the other account: it must accept the peering itself and cannot be managed by this module."
  type = map(object({
    accepter_net_id       = string
    accepter_owner_id     = optional(string)
    source_net_account_id = optional(string)
    auto_accept           = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.net_peerings) : v.source_net_account_id == null ? true : can(regex("^[0-9]{12}$", v.source_net_account_id))])
    error_message = "source_net_account_id must be a 12-digit Outscale account id."
  }
}

variable "enable_net_access_points" {
  description = "Whether to create Net access points (VPC endpoints)"
  type        = bool
  default     = false
}

variable "net_access_points" {
  description = "Map of Net access point definitions. service_name is the Outscale service name (e.g., 'com.outscale.eu-west-2.api'). route_table_keys reference keys in the route_tables variable."
  type = map(object({
    service_name     = string
    route_table_keys = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# Optional — Routing
################################################################################

variable "route_tables" {
  description = "Map of route table definitions. subnet_keys reference keys in the subnets variable. routes define individual route entries with a destination and at most one target (use_internet_service or gateway_id, nat_key, peering_key, or nic_key). Set use_internet_service to true to route via the module's Internet Service (requires enable_internet_service = true), or pass a gateway_id for external gateways."
  type = map(object({
    subnet_keys = optional(list(string), [])
    routes = optional(list(object({
      destination_ip_range = string
      use_internet_service = optional(bool, false)
      gateway_id           = optional(string)
      nat_key              = optional(string)
      peering_key          = optional(string)
      nic_key              = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for rt in var.route_tables : [
        for route in rt.routes :
        (route.use_internet_service || route.gateway_id != null ? 1 : 0) + (route.nat_key != null ? 1 : 0) + (route.peering_key != null ? 1 : 0) + (route.nic_key != null ? 1 : 0) <= 1
      ]
    ]))
    error_message = "Each route must set at most one target: use_internet_service or gateway_id, nat_key, peering_key, or nic_key."
  }

  validation {
    condition = var.enable_internet_service || !anytrue(flatten([
      for rt in var.route_tables : [for route in rt.routes : route.use_internet_service]
    ]))
    error_message = "A route with use_internet_service = true requires enable_internet_service = true."
  }
}

variable "main_route_table_key" {
  description = "Key from route_tables to set as the main route table for the Net"
  type        = string
  default     = null
}

################################################################################
# Optional — Services
################################################################################

variable "enable_load_balancers" {
  description = "Whether to create load balancers"
  type        = bool
  default     = false
}

variable "load_balancers" {
  description = "Map of load balancer definitions. subnet_keys reference keys in the subnets variable. secured_cookies enables secure cookies. public_ip_key references a key in public_ips to give an internet-facing load balancer a fixed public IP. subregion_names places a load balancer outside a Net and excludes subnet_keys; changing it replaces the load balancer. Unsetting secured_cookies or public_ip_key later does not revert them: set the new value explicitly."
  type = map(object({
    load_balancer_name = string
    load_balancer_type = optional(string, "internet-facing")
    subnet_keys        = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    secured_cookies    = optional(bool)
    public_ip_key      = optional(string)
    subregion_names    = optional(list(string))
    listeners = list(object({
      backend_port           = number
      backend_protocol       = string
      load_balancer_port     = number
      load_balancer_protocol = string
      server_certificate_id  = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.load_balancers) : v.subregion_names == null || length(v.subnet_keys) == 0])
    error_message = "subnet_keys and subregion_names are mutually exclusive: use subnet_keys for a load balancer in a Net or subregion_names outside a Net."
  }

  validation {
    condition     = alltrue([for v in values(var.load_balancers) : v.public_ip_key == null || v.load_balancer_type == "internet-facing"])
    error_message = "public_ip_key requires load_balancer_type = \"internet-facing\"."
  }

  validation {
    condition     = alltrue([for v in values(var.load_balancers) : v.public_ip_key == null ? true : contains(keys(var.public_ips), v.public_ip_key)])
    error_message = "public_ip_key must be a key of public_ips."
  }
}

variable "nics" {
  description = "Map of Network Interface Card (NIC) definitions"
  type = map(object({
    subnet_key         = string
    description        = optional(string)
    security_group_ids = optional(list(string), [])
    private_ips = optional(list(object({
      private_ip = string
      is_primary = bool
    })), [])
  }))
  default = {}
}
