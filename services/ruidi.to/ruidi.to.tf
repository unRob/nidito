terraform {
  backend "consul" {
    path = "nidito/state/service/ruidi.to"
  }

  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.18.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.29.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "vault_generic_secret" "garage" {
  path = "cfg/svc/tree/nidi.to:garage"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

data "terraform_remote_state" "rob_mx" {
  backend = "consul"
  workspace = "default"
  config = {
    datacenter = "casa"
    path = "nidito/state/rob.mx"
  }
}

resource "digitalocean_domain" "fqdn" {
  name       = "ruidi.to"
  ip_address = data.terraform_remote_state.rob_mx.outputs.bernal.ip
}

# resource "digitalocean_record" "www" {
#   domain = "ruidi.to"
#   type   = "CNAME"
#   ttl    = 180
#   name   = "www"
#   value  = "ruidi.to."
# }

module "storage" {
  source = "../../terraform/_modules/bucket/vultr"
  # no dots allowed on vultr :/
  name = "ruidi-to"
}

resource "consul_keys" "cdn-config" {
  datacenter = "qro0"
  key {
    path = "cdn/ruidi.to"
    value = jsonencode({
     cert = "ruidi.to"
     host = module.storage.endpoint
     bucket = module.storage.bucket
    })
  }
}


module "audio" {
  source = "../../terraform/_modules/bucket/garage"
  # no dots allowed on vultr :/
  name = "ruiditos"
  website_access = true
}

output "bucket" {
  value = module.audio.bucket
  description = "the bucket id"
}

output "cdn" {
  value = "${module.storage.endpoint}/${module.storage.bucket}"
}
