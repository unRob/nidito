terraform {
  backend "consul" {
    path = "nidito/state/service/ssl"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
  dc = terraform.workspace
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "ssl"
  configs = [
    "dc:${local.dc}",
    "provider:digitalocean",
  ]
  consul_creds = ["service-ssl"]

  extra_rules = <<-HCL
  path "nidito/tls/*" {
    capabilities = ["create", "read", "update", "list"]
  }

  path "auth/token/create" {
    capabilities = ["create", "read", "update", "list"]
  }
  HCL
}

module "consul-policy" {
  count = local.dc == "casa" ? 1 : 0
  source = "../../terraform/_modules/service/consul-policy"
  name = "ssl"

  prefixes = {
    "nidito/state/letsencrypt/registration" = "read"
    "nidito/state/letsencrypt" = "read"
    "nidito/state/letsencrypt-env:" = "list"
    "nidito/state/letsencrypt-env:*" = "write"
    "nidito/state/letsencrypt-env:casa" = "write"
    "nidito/state/letsencrypt-env:nyc1" = "write"
    "nidito/state/letsencrypt-env:*/" = "write"
    "nidito/state/letsencrypt-env:*/.tfstate" = "write"
    "nidito/state/letsencrypt-env:*/.lock" = "write"
    "nidito/state/letsencrypt-env:casa/.lock" = "write"
    "nidito/state/letsencrypt-env:nyc1/.lock" = "write"
  }

  read_consul_data = true
  create_service_token = false
  create_local_token = false
  create_vault_role = true

  session_prefixes = {
    "" = "write"
  }
}

// nyc1 also needs to get a consul role to query state
data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = local.dc
  config = {
    path = "nidito/state/vault"
  }
}

resource "vault_consul_secret_backend_role" "service" {
  count = local.dc != "casa" ? 1 : 0
  name    = "service-ssl"
  backend = data.terraform_remote_state.vault.outputs.consul_backend_name
  policies = ["service-ssl"]
  ttl = 600
  max_ttl = 86400
}
