terraform {
  backend "consul" {
    path = "nidito/state/service/event-gateway"
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

  required_version = ">= 1.2.0"
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "event-gateway"
  configs = [
    "provider:honeycomb",
    "service:ca"
  ]
  consul_creds = [module.consul-policy.name]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "evgw"
}

module "consul-policy" {
  source = "../../terraform/_modules/service/consul-policy"
  name = "event-gateway"
  create_vault_role = true
}

resource "nomad_acl_policy" "event-gateway" {
  name = "event-gateway-triggers-jobs"
  job_acl {
    job_id = "event-gateway"
    group = "event-gateway"
    task = "event-gateway"
    namespace = "infra-runtime"
  }
  rules_hcl = <<HCL
namespace "*" {
  policy = "read"
  capabilities = ["dispatch-job"]
}
HCL
}
