terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 1.0.0"
}

variable "service" {
  type = string
  description = "The service name to setup"
}

variable "redirect_uris" {
  type = list(string)
  description = "A list of uris to redirect to"
}

data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = "casa"
  config = {
    path = "nidito/state/vault"
  }
}

# https://developer.hashicorp.com/nomad/tutorials/single-sign-on/sso-oidc-vault#create-a-vault-oidc-client
resource "vault_identity_oidc_key" "key" {
  name               = var.service
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
  algorithm          = "RS256"
}

resource "vault_identity_oidc_client" "client" {
  name = var.service
  key  = vault_identity_oidc_key.key.name
  redirect_uris = var.redirect_uris
  assignments = [
    data.terraform_remote_state.vault.outputs.admin_oidc_assignment.name
  ]

  id_token_ttl     = 2400
  access_token_ttl = 7200
}

resource "vault_identity_oidc_provider" "provider" {
  name          = var.service
  https_enabled = true
  issuer_host   = "vault.nidi.to"
  allowed_client_ids = [
    vault_identity_oidc_client.client.client_id
  ]
  scopes_supported = [
    "user",
    "groups"
  ]
}


data "vault_identity_oidc_client_creds" "client" {
  name = vault_identity_oidc_client.client.name
}


data "vault_identity_oidc_openid_config" "service" {
  name = vault_identity_oidc_provider.provider.name
}

output "config" {
  value = jsonencode({
    issuer_url = data.vault_identity_oidc_openid_config.service.issuer
    client = {
      id = data.vault_identity_oidc_client_creds.client.client_id
      secret = nonsensitive(data.vault_identity_oidc_client_creds.client.client_secret)
    }
  })
  description = "the issuer_id and client's id and secret"
}
