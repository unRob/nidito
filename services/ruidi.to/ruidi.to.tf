terraform {
  backend "consul" {
    path = "nidito/state/service/ruidi.to"
  }

  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.18.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.29.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    garage = {
      source = "nidito/garage"
      version = "0.0.1"
    }
  }

  required_version = ">= 1.0.0"
}

provider "garage" {
  host = "api.garage.nidi.to"
  scheme = "https"
  token = jsondecode(data.vault_generic_secret.garage.data.token).admin
}

data "vault_generic_secret" "garage" {
  path = "cfg/svc/tree/nidi.to:garage"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
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

resource "consul_keys" "cdn-config" {
  datacenter = "nyc1"
  key {
    path = "cdn/ruidi.to"
    value = "ruidi.to"
  }
}


resource "garage_bucket" "ruiditos" {
  website_access_enabled = true
  website_config_error_document = "error.html"
  website_config_index_document = "index.html"
}

resource "garage_bucket_global_alias" "ruiditos_alias" {
  bucket_id = garage_bucket.ruiditos.id
  alias     = "ruiditos"
}

output "bucket" {
  value = garage_bucket.ruiditos.id
  description = "the bucket id"
}
