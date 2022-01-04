terraform {
  backend "consul" {
    path = "nidito/state/service/cajon"
  }

  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.16.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "minio"
  paths = [
    "config/services/minio",
  ]
}

provider "digitalocean" {
  # token = data.vault_generic_secret.dns.data.token
  # spaces_access_id = data.vault_generic_secret.cdn.data.key
  # spaces_secret_key = data.vault_generic_secret.cdn.data.secret
}

data "vault_generic_secret" "dns" {
  path = "nidito/config/services/dns/external/provider"
}

data "vault_generic_secret" "cdn" {
  path = "nidito/config/services/cdn"
}


resource "digitalocean_spaces_bucket" "bucket" {
  name   = "cdn.rob.mx"
  region = "nyc3"
  acl = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://rob.mx", "https://*.rob.mx", "https://nidi.to", "https://*.nidi.to"]
    max_age_seconds = 3600
  }
}

resource "digitalocean_certificate" "cert" {
  name    = "mx.rob.cdn"
  type    = "lets_encrypt"
  domains = ["rob.mx", "cdn.rob.mx"]
}


resource "digitalocean_cdn" "cdn" {
  origin = digitalocean_spaces_bucket.bucket.bucket_domain_name
  custom_domain = "cdn.rob.mx"
  certificate_name = digitalocean_certificate.cert.name
}

