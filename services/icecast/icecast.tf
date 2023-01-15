terraform {
  backend "consul" {
    path = "nidito/state/service/icecast"
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
  name = "icecast"
  services = ["cajon"]
  configs = ["service:dns"]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "radio"
}
