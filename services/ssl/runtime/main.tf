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
      version = "~> 2.5.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.7.0"
    }
  }

  required_version = ">= 1.2.0"
}

variable "lookup_domains" {
  default = true
  description = "lookup domains in vault"
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

data "vault_generic_secret" "dns" {
  path = "nidito/config/datacenters/${local.dc}/dns"
}

data "vault_kv_secrets_list" "domains" {
  count = var.lookup_domains ? 1 : 0
  path       = "nidito/service/ssl/domains"
}

data "vault_generic_secret" "provider_dns" {
  path = "nidito/config/providers/digitalocean"
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

locals {
  domains = nonsensitive(
    toset(
      concat(
        [data.vault_generic_secret.dns.data.zone],
        var.lookup_domains ? data.vault_kv_secrets_list.domains[0].names : []
      )
    )
  )
}

resource acme_certificate cert {
  for_each = local.domains
  account_key_pem           = data.terraform_remote_state.registration.outputs.account_key
  common_name               = each.value
  subject_alternative_names = ["*.${each.value}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "digitalocean"
    config = {
      DO_AUTH_TOKEN = data.vault_generic_secret.provider_dns.data.token
      DO_PROPAGATION_TIMEOUT = 60
      DO_TTL = 30
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
