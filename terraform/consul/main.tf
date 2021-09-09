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

resource "consul_prepared_query" "dns-services" {

  template {
    type   = "name_prefix_match"
    regexp = "^(.+)$"
  }

  service = "$${match(1)}"

  name         = "dns-services"
  only_passing = false

  tags = ["nidito.dns.enabled"]
}

locals {
  static_entries = {
    consul = 5555
    nomad = 5560
    vault = 5570
  }
}

resource "consul_keys" "static-services" {
  datacenter = "casa"
  key {
    delete = false
    path = "dns/static-entries"
    value = jsonencode(zipmap(
      keys(local.static_entries),
      [for name, port in local.static_entries : {
        target = "@service_proxy"
        acl    = ["allow altepetl"]
        port = port
      }]
    ))
  }
}
