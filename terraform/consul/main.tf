terraform {
  backend "consul" {
    path = "nidito/state/consul"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18.0"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
  static_entries = {
    // todo: pull these from config
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


resource "consul_acl_policy" "vault" {
  name  = "vault-secret-backend"
  rules = <<-RULE
    acl = "write"
  RULE
}

resource "consul_acl_token" "vault_backend" {
  description = "vault backend token"
  policies = [consul_acl_policy.vault.name]
  local = false
}

output vault_backend_token {
  description = "vault token to use for consul secret backend"
  value = consul_acl_token.vault_backend.accessor_id
}

