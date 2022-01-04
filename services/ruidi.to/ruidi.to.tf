terraform {
  backend "consul" {
    path = "nidito/state/service/ruidi.to"
  }

  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.5.3"
    }
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.14.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.16.0"
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

provider "digitalocean" {
  token = data.vault_generic_secret.dns.data.token
}

variable "vault_password" {
  description = "the password to authenticate to vault with as a user"
}


data "vault_generic_secret" "dns" {
  path = "nidito/config/services/dns/external/provider"
}


data "digitalocean_droplet" "bedstuy" {
  name = "bedstuy"
}

resource "digitalocean_domain" "fqdn" {
  name       = "ruidi.to"
  ip_address = data.digitalocean_droplet.bedstuy.ipv4_address
}

resource "digitalocean_record" "www" {
  domain = "ruidi.to"
  type   = "CNAME"
  ttl    = 180
  name   = "www"
  value  = "ruidi.to."
}

module "tls" {
  source = "../../terraform/_modules/tls-cert"
  domain_name = "ruidi.to"
  digitalocean_token = data.vault_generic_secret.dns.data.token
  dc = "nyc1"
  vault_password = var.vault_password
}

resource "consul_keys" "cdn-config" {
  datacenter = "nyc1"
  key {
    path = "cdn/ruidi.to"
    value = "ruidi.to"
  }
}
