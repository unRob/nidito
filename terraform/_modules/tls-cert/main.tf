terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.5.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}


variable "domain_name" {
  description = "The dns name to issue a tls cert for"
}

variable "digitalocean_token" {
  description = "The DO token to use for creating DNS challenge records"
}

variable "vault_password" {
  description = "the password to authenticate to vault with as a user"
}

variable "dc" {
  description = "The DC to store the token in"
  default = "casa"
}


data "terraform_remote_state" "registration" {
  backend = "consul"
  workspace = "default"
  config = {
    path = "nidito/state/letsencrypt/registration"
  }
}

resource "acme_certificate" "cert" {
  account_key_pem           = data.terraform_remote_state.registration.outputs.account_key
  common_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "digitalocean"
    config = {
      DO_AUTH_TOKEN = var.digitalocean_token
      DO_PROPAGATION_TIMEOUT = 60
      DO_TTL = 30
    }
  }
}

provider "vault" {
  alias = "tls"
  address = "https://vault.service.${var.dc}.consul:5570"
  auth_login {
    path = "auth/userpass/login/rob"
    parameters = {
      password = var.vault_password
      token_ttl = 60
    }
  }
}

resource "vault_generic_secret" "cert" {
  provider = vault.tls
  path = "nidito/tls/${var.domain_name}"
  data_json = jsonencode({
    private_key = acme_certificate.cert.private_key_pem,
    cert = join("", [
      acme_certificate.cert.certificate_pem,
      acme_certificate.cert.issuer_pem,
    ])
    issuer = acme_certificate.cert.issuer_pem,
    bare_cert = acme_certificate.cert.certificate_pem,
  })
}
