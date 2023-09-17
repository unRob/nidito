terraform {
  backend "consul" {
    path = "nidito/state/service/puerta"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.29.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "puerta"
  configs = ["service:dns"]
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}


provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "puerta"
}
