terraform {
  backend "consul" {
    path = "nidito/state/service/prom-hue-exporter"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "prom-hue-exporter"
}
