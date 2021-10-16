terraform {
  backend "consul" {
    path = "nidito/state/letsencrypt"
  }

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

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

locals {
  dc = terraform.workspace
}

data "vault_generic_secret" "dns" {
  path = "nidito/config/datacenters/${local.dc}/dns"
}

data "vault_generic_secret" "dns_provider" {
  path = "nidito/config/services/dns/external/provider"
}

data "terraform_remote_state" "registration" {
  backend = "consul"
  workspace = "default"
  config = {
    path = "nidito/state/letsencrypt/registration"
  }
}

resource acme_certificate main-cert {
  account_key_pem           = data.terraform_remote_state.registration.outputs.account_key
  common_name               = data.vault_generic_secret.dns.data.zone
  subject_alternative_names = ["*.${data.vault_generic_secret.dns.data.zone}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "digitalocean"
    config = {
    DO_AUTH_TOKEN = data.vault_generic_secret.dns_provider.data.token
    DO_PROPAGATION_TIMEOUT = 60
    DO_TTL = 30
  }
  }
}

resource vault_generic_secret main-cert {
  path = "nidito/tls/${data.vault_generic_secret.dns.data.zone}"
  data_json = jsonencode({
    private_key = acme_certificate.main-cert.private_key_pem,
    cert = join("\n", [
      acme_certificate.main-cert.certificate_pem,
      acme_certificate.main-cert.issuer_pem,
    ])
    issuer = acme_certificate.main-cert.issuer_pem,
    bare_cert = acme_certificate.main-cert.certificate_pem,
  })
}
