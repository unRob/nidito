terraform {
  backend "consul" {
    path = "nidito/state/service/home-assistant"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    nomad = {
      source = "hashicorp/nomad"
      version = "2.2.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "home-assistant"
  configs = [ "net:altepetl", "service:ca" ]
}

module "bucket_key" {
  source = "../../terraform/_modules/bucket/garage/key"
  name = "home-assistant"
}

module "bucket" {
  source = "../../terraform/_modules/bucket/garage"
  name = "home-assistant-config"
  grants = {
    self = {
      key_id = module.bucket_key.id
      write = true
    }
  }
}

output "credentials" {
  value = module.bucket_key.credentials
  description = "the key credentials"
  sensitive = true
}
