terraform {
  required_version = ">= 1.10"

  required_providers {
    outscale = {
      source  = "outscale/outscale"
      version = "~> 1.0"
    }
  }
}

provider "outscale" {}

module "networking" {
  source = "../../"

  ip_range = "10.0.0.0/16"
  tenancy  = "default"

  subnets = {
    public_a = {
      ip_range       = "10.0.1.0/24"
      subregion_name = "eu-west-2a"
    }
    public_b = {
      ip_range       = "10.0.2.0/24"
      subregion_name = "eu-west-2b"
    }
    private_a = {
      ip_range       = "10.0.10.0/24"
      subregion_name = "eu-west-2a"
    }
    private_b = {
      ip_range       = "10.0.11.0/24"
      subregion_name = "eu-west-2b"
    }
  }

  # DHCP Options
  dhcp_domain_name         = "example.internal"
  dhcp_domain_name_servers = ["10.0.0.2"]
  dhcp_ntp_servers         = ["10.0.0.3"]

  # Internet Service
  enable_internet_service = true

  # NAT Services
  enable_nat_services = true
  nat_services = {
    nat_a = {
      subnet_key = "public_a"
    }
  }

  # Standalone Public IPs
  public_ips = {
    bastion = {
      tags = { Purpose = "bastion-host" }
    }
  }

  # Net Peering — uncomment and replace with a real Net ID to test
  # enable_net_peerings = true
  # net_peerings = {
  #   to_shared_services = {
  #     accepter_net_id   = "vpc-REPLACE_ME"  # real Net ID required
  #     accepter_owner_id = "REPLACE_ME"      # required for cross-account
  #     auto_accept       = true              # same-account only
  #   }
  # }

  # Net Access Points
  enable_net_access_points = true
  net_access_points = {
    api = {
      service_name     = "com.outscale.eu-west-2.api"
      route_table_keys = ["private"]
    }
  }

  # Route Tables
  route_tables = {
    public = {
      subnet_keys = ["public_a", "public_b"]
      routes = [
        {
          destination_ip_range = "0.0.0.0/0"
          use_internet_service = true
        }
      ]
    }
    private = {
      subnet_keys = ["private_a", "private_b"]
      routes = [
        {
          destination_ip_range = "0.0.0.0/0"
          nat_key              = "nat_a"
        }
      ]
    }
  }

  main_route_table_key = "private"

  # Load Balancers (Outscale supports one subnet per load balancer)
  enable_load_balancers = true
  load_balancers = {
    web = {
      load_balancer_name = "web-lb"
      load_balancer_type = "internet-facing"
      subnet_keys        = ["public_a"]
      listeners = [
        {
          backend_port           = 80
          backend_protocol       = "HTTP"
          load_balancer_port     = 80
          load_balancer_protocol = "HTTP"
        }
      ]
      tags = { Service = "web" }
    }
  }

  # NICs
  nics = {
    app_a = {
      subnet_key  = "private_a"
      description = "Application NIC in AZ-a"
      private_ips = [
        {
          private_ip = "10.0.10.100"
          is_primary = true
        }
      ]
    }
  }

  tags = {
    Project     = "complete-example"
    Environment = "staging"
  }
}
