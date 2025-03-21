terraform {
  backend "consul" {
    path = "nidito/state/service/op-connect"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }

    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.21.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider consul {
  address = "https://consul.service.${terraform.workspace}.consul:5554"
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
