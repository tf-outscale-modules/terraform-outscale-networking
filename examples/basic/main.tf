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

  subnets = {
    public_a = {
      ip_range       = "10.0.1.0/24"
      subregion_name = "eu-west-2a"
    }
    public_b = {
      ip_range       = "10.0.2.0/24"
      subregion_name = "eu-west-2b"
    }
  }

  enable_internet_service = true

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
  }

  tags = {
    Project     = "example"
    Environment = "dev"
  }
}
