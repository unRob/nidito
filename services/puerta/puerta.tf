terraform {
  backend "consul" {
    path = "nidito/state/service/puerta"
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
  name = "puerta"
  paths = [
    "config/services/dns",
  ]
}

module "consul-policy" {
  source = "../../terraform/_modules/service/consul-policy"
  name = "puerta"
  create_service_token = true
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "puerta"
}
