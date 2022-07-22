terraform {
  backend "consul" {
    path = "nidito/state/service/ssl"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.15.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.7.0"
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
  paths = [
    "nidito/config/services/dns/external/provider",
    "nidito/config/datacenters/${local.dc}/dns",
  ]
}

module "consul-policy" {
  count = local.dc == "casa" ? 1 : 0
  source = "../../terraform/_modules/service/consul-policy"
  name = "ssl"

  prefixes = {
    "nidito/state/letsencrypt/registration" = "read"
    "nidito/state/letsencrypt" = "read"
    "nidito/state/letsencrypt-env:" = "list"
    "nidito/state/letsencrypt-env:${local.dc}" = "write"
    "nidito/state/letsencrypt-env:${local.dc}/.tfstate" = "write"
    "nidito/state/letsencrypt-env:*" = "read"
  }

  read_consul_data = true
  create_service_token = false
  create_local_token = false
  create_vault_role = true

  session_prefixes = {
    "" = "write"
  }
}
