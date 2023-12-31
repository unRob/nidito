terraform {
  backend "consul" {
    # talk to casa, since we don't store state elsewhere
    address = "consul.service.casa.consul:5554"
    scheme = "https"
    # this is not a service path intentionally
    path = "nidito/state/letsencrypt"
  }

  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.15.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }

  required_version = ">= 1.2.0"
}

variable "domains" {
  type = map(object({
    provider = string
    token = string
  }))
  default = {}
  description = "domains"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "vault" {
  address = "https://vault.service.${terraform.workspace}.consul:5570"
}

locals {
  dc = terraform.workspace
}

data "vault_generic_secret" "dc" {
  path = "cfg/infra/tree/dc:${local.dc}"
}

data "vault_generic_secret" "provider_digitalocean" {
  path = "cfg/infra/tree/provider:digitalocean"
}

data "vault_generic_secret" "provider_cloudflare" {
  path = "cfg/infra/tree/provider:cloudflare"
}

data "terraform_remote_state" "registration" {
  backend = "consul"
  workspace = "default"
  config = {
    address = "consul.service.casa.consul:5554"
    scheme = "https"
    path = "nidito/state/letsencrypt/registration"
  }
}

resource acme_certificate cert {
  for_each = var.domains
  account_key_pem           = data.terraform_remote_state.registration.outputs.account_key
  common_name               = each.key
  subject_alternative_names = ["*.${each.key}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = each.value.provider
    config = each.value.provider == "digitalocean" ? {
      DO_AUTH_TOKEN = data.vault_generic_secret.provider_digitalocean.data[each.value.token == "default" ? "token" : each.value.token]
      DO_PROPAGATION_TIMEOUT = 60
      DO_TTL = 30
    } : {
      CF_DNS_API_TOKEN = data.vault_generic_secret.provider_cloudflare.data.token
    }
  }
}

resource vault_generic_secret cert {
  for_each = acme_certificate.cert
  path = "nidito/tls/${each.value.common_name}"
  data_json = jsonencode({
    private_key = each.value.private_key_pem,
    cert = join("", [
      each.value.certificate_pem,
      each.value.issuer_pem,
    ])
    issuer = each.value.issuer_pem,
    bare_cert = each.value.certificate_pem,
  })
}
