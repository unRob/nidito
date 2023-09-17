terraform {
  backend "consul" {
    path = "nidito/state/service/op-connect"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "op"
}

resource "consul_prepared_query" "op" {
  name = "op"
  only_passing = true
  near = "_agent"
  service = "op"

  failover {
    nearest_n = 1
  }

  dns {
    ttl = "30s"
  }
}
