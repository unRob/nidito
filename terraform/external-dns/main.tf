terraform {
  backend "consul" {
    path = "nidito/state/external-dns"
  }

  required_version = ">= 0.12.20"
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

data "consul_key_prefix" "cfg" {
  path_prefix = "/nidito/config"
}

resource "digitalocean_domain" "root" {
  name = data.vault_generic_secret.dns_zone.data["zone"]
}

resource "digitalocean_record" "txt_root" {
  domain = digitalocean_domain.root.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:mailgun.org ~all;"
}

output "zone" {
  value = digitalocean_domain.root.name
  description = "this zone's root name"
}
