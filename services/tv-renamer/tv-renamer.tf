terraform {
  backend "consul" {
    path = "nidito/state/service/tv-renamer"
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
  name = "tv-renamer"
  paths = [
    "config/third-party/tvdb"
  ]
}
