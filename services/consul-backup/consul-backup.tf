terraform {
  backend "consul" {
    path = "nidito/state/service/consul-backup"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
  dc = terraform.workspace
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "consul-backup"
  configs = [
    "service:consul",
    "service:ca"
  ]
}
