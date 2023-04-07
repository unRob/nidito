terraform {
  backend "consul" {
    path = "nidito/state/service/prometheus"
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
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "prometheus"
  configs = ["service:consul", "service:ca"]
}

module "consul-policy" {
  source = "../../terraform/_modules/service/consul-policy"
  name = "prometheus"

  prefixes = {
    prometheus = "write"
  }

  read_consul_data = true
  create_service_token = true
  create_local_token = false
}
