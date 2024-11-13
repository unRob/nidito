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
  configs = [ "net:altepetl" ]
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


resource "nomad_csi_volume_registration" "config" {
  volume_id = "home-assistant-config"
  name = "home-assistant-config"
  plugin_id = "csi-s3"
  external_id = "home-assistant-config"
  namespace = "home"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  secrets = {
    accessKeyID     = module.bucket_key.credentials.key
    secretAccessKey = module.bucket_key.credentials.secret
    endpoint        = "https://${module.bucket.endpoint}"
    region          = "garage"
  }

  parameters = {
    mounter = "s3fs"
  }
}

output "credentials" {
  value = module.bucket_key.credentials
  description = "the key credentials"
  sensitive = true
}
