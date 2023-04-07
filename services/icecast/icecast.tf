terraform {
  backend "consul" {
    path = "nidito/state/service/icecast"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }

     consul = {
      source  = "hashicorp/consul"
      version = "~> 2.17.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "icecast"
  services = ["nidi.to:cajon"]
  configs = ["service:dns"]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "radio"
}
