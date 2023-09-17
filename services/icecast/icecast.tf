terraform {
  backend "consul" {
    path = "nidito/state/service/icecast"
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

    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0.0"
    }

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.29.0"
    }

    garage = {
      source = "prologin/garage"
      version = "0.0.1"
    }
  }

  required_version = ">= 1.0.0"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "icecast"
  services = ["nidi.to:cajon"]
  configs = ["service:dns"]
  nomad_roles = [nomad_acl_role.icecast.name]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "radio"
}

resource "nomad_acl_policy" "icecast" {
  name = "icecast-triggers-radio-processing"
  job_acl {
    job_id = "radio"
    group = "radio"
    task = "radio"
  }
  rules_hcl = <<HCL
namespace "default" {
  policy = "read"
  capabilities = ["dispatch-job"]
}
HCL
}

resource "vault_nomad_secret_role" "icecast" {
  backend   = "nomad"
  role      = nomad_acl_role.icecast.name
  type      = "client"
  policies  = [nomad_acl_policy.icecast.name]
}

resource "nomad_acl_role" "icecast" {
  name        = "service-icecast"
  description = "icecast service"

  policy {
    name = nomad_acl_policy.icecast.name
  }
}

data "terraform_remote_state" "ruidi_to" {
  backend = "consul"
  config = {
    path = "nidito/state/service/ruidi.to"
  }
}

provider "garage" {
  host = "api.garage.nidi.to"
  scheme = "https"
  token = jsondecode(data.vault_generic_secret.garage.data.token).admin
}

data "vault_generic_secret" "garage" {
  path = "cfg/svc/tree/nidi.to:garage"
}

resource "garage_key" "key" {
  name = "icecast"
  permissions = {
    create_bucket = false
  }
}

resource "garage_bucket_key" "bucket_grant" {
  bucket_id     = data.terraform_remote_state.ruidi_to.outputs.bucket
  access_key_id = garage_key.key.access_key_id
  read          = true
  write = true
}
