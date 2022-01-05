terraform {
  backend "consul" {
    path = "nidito/state/external-dns"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.13.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.16.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "vault_generic_secret" "do_token" {
  path = "nidito/config/services/dns/external/provider"
}

data "vault_generic_secret" "dns_zone" {
  path = "nidito/config/services/dns"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do_token.data["token"]
}

resource "digitalocean_domain" "root" {
  name = nonsensitive(data.vault_generic_secret.dns_zone.data["zone"])
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
