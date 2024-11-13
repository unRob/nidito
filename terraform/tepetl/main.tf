terraform {
  backend "consul" {
    path = "nidito/state/tepetl"
  }

  required_providers {
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

provider "digitalocean" {
  token = data.vault_generic_secret.do_token.data.token
}

data "vault_generic_secret" "dns" {
  path = "cfg/infra/tree/service:dns"
}

resource "digitalocean_domain" "root" {
  name = nonsensitive(data.vault_generic_secret.dns.data.zone)
}

output "zone" {
  value       = digitalocean_domain.root.name
  description = "this zone's root name"
}

/*
# "cloud" DC DNS records are managed in a different repo
# main DC's record is managed by firewall's nsupdate script
# see ansible/roles/gateway/files/dyndns.sh

data "external" "dcs" {
  program = [
    "milpa", "nidito", "dc", "ips", "--format", "json"
  ]
}

resource "digitalocean_record" "dc" {
  for_each = data.external.dcs.result
  domain = digitalocean_domain.root.name
  type = "A"
  name = each.key
  value = each.value
}
*/
