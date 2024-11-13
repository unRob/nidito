terraform {
  backend "consul" {
    path = "nidito/state/letsencrypt/registration"
  }

  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.26.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

locals {
  dc = terraform.workspace == "default" ? "casa" : terraform.workspace
}

data "vault_generic_secret" "le" {
  path = "cfg/infra/tree/provider:letsencrypt"
}

resource "acme_registration" "account" {
  account_key_pem = trim(data.vault_generic_secret.le.data.private_key, "\n")
  email_address   = data.vault_generic_secret.le.data.email
}

output account_key {
  value = acme_registration.account.account_key_pem
  sensitive = true
}
