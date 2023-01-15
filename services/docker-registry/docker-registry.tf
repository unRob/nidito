terraform {
  backend "consul" {
    path = "nidito/state/service/docker-registry"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "docker-registry"
  configs = ["service:dns"]
}
