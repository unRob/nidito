terraform {
  backend "consul" {
    path = "nidito/state/consul"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.13.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

locals {
  static_entries = {
    consul = 5554
    nomad  = 5560
    vault  = 5570
  }
}

resource "consul_keys" "static-services" {
  datacenter = "casa"
  key {
    delete = false
    path   = "dns/static-entries"
    value = jsonencode(zipmap(
      keys(local.static_entries),
      [for name, port in local.static_entries : {
        target = "@service_proxy"
        acl    = ["allow altepetl"]
        port   = port
      }]
    ))
  }
}
