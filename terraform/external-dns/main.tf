terraform {
  backend "consul" {
    path = "nidito/state/external-dns"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.21.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.29.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "vault_generic_secret" "do_token" {
  path = "cfg/infra/tree/provider:digitalocean"
}

data "vault_generic_secret" "dns_zone" {
  path = "cfg/infra/tree/service:dns"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do_token.data.token
}

resource "digitalocean_domain" "root" {
  name = nonsensitive(data.vault_generic_secret.dns_zone.data.zone)
}

resource "digitalocean_record" "txt_root" {
  domain = digitalocean_domain.root.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:mailgun.org ~all;"
}

output "zone" {
  value       = digitalocean_domain.root.name
  description = "this zone's root name"
}
