terraform {
  backend "consul" {
    path = "nidito/state/service/garage"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.17.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.27.1"
    }

  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "garage"
  configs = [
    "dc:${terraform.workspace}",
    "service:ca"
  ]

  consul_creds = ["service-garage"]
}

resource "consul_acl_policy" "service" {
  name = "service-garage"
  rules = <<-HCL
  service_prefix "" {
    policy = "read"
  }

  service "garage" {
    policy = "write"
  }

  // needed to list catalog services for some reason
  // https://developer.hashicorp.com/consul/docs/security/acl/acl-rules#node-rules
  node_prefix "" {
    policy = "read"
  }
  HCL
}

data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = terraform.workspace
  config = {
    path = "nidito/state/vault"
  }
}

resource "vault_consul_secret_backend_role" "service" {
  name    = "service-garage"
  backend = data.terraform_remote_state.vault.outputs.consul_backend_name
  policies = ["service-garage"]
  ttl = 600
  max_ttl = 86400
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

data "vault_generic_secret" "dc" {
  path = "cfg/infra/tree/dc:${terraform.workspace}"
}

locals {
  dns_zone = nonsensitive(jsondecode(data.vault_generic_secret.dc.data_json).dns.zone)
}

resource "digitalocean_record" "service" {
  domain = local.dns_zone
  type   = "CNAME"
  ttl    = 180
  name   = "garage"
  value  = "${local.dns_zone}."
}

resource "digitalocean_record" "s3" {
  domain = local.dns_zone
  type   = "CNAME"
  ttl    = 180
  name   = "s3.garage"
  value  = "${local.dns_zone}."
}

resource "digitalocean_record" "web" {
  domain = local.dns_zone
  type   = "CNAME"
  ttl    = 180
  name   = "web.garage"
  value  = "${local.dns_zone}."
}

resource "vault_generic_secret" "ssl-req" {
  path = "nidito/service/ssl/domains/garage.nidi.to"
  data_json = jsonencode({
    "star": true,
    "token": "default"
  })
}

# resource "consul_keys" "cdn-config" {
#   datacenter = "${terraform.workspace}"
#   key {
#     path = "nidito/service/http-proxy/cdn"
#     value = jsonencode({
#       buckets = "s3.garage.${data.vault_generic_secret.dc.data.dns.zone}"
#     })
#   }
# }
