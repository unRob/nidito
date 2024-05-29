terraform {
  backend "consul" {
    path = "nidito/state/service/grafana"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.2.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "grafana"
  # configs = ["service:dns"]
}

# module "oidc" {
#   source = "../../terraform/_modules/service/oidc"
#   service = "grafana"
#   redirect_uris = [
#     "https://grafana.nidi.to/login/generic_oauth"
#   ]
# }

# output "oidc-config" {
#   value = module.oidc.config
# }

module "key" {
  source = "../../terraform/_modules/bucket/garage/key"
  name = "grafana-litestream"
}

module "bucket" {
  source = "../../terraform/_modules/bucket/garage"
  name = "grafana-db"
  grants = {
    litestream = {
      key_id = module.key.id
      write = true
    }
  }
}

output "bucket" {
  value = module.bucket.bucket
  description = "the bucket id"
}

output "credentials" {
  value = module.key.credentials
  sensitive = true
  description = "credentials for litestream"
}
