terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    garage = {
      source = "nidito/garage"
      version = "0.1.0"
    }
  }
}

variable "name" {
  description = "the name of the bucket to create"
  type = string
}

variable "grants" {
  description = "the grants to apply, read enabled by default"
  type = map(object({
    bucket_id = string
    write = bool
  }))
  default = {}
}

data "vault_generic_secret" "garage" {
  path = "cfg/svc/tree/nidi.to:garage"
}

provider "garage" {
  host = "api.garage.nidi.to"
  scheme = "https"
  token = jsondecode(data.vault_generic_secret.garage.data.token).admin
}

resource "garage_key" "key" {
  name = var.name
  permissions = {
    create_bucket = false
  }
}

resource "garage_bucket_key" "bucket_grant" {
  for_each      = var.grants
  bucket_id     = each.value.bucket_id
  access_key_id = garage_key.key.access_key_id
  read          = true
  write         = each.value.write
}


output "credentials" {
  value = {
    key = garage_key.key.access_key_id
    secret = garage_key.key.secret_access_key
  }
  description = "credentials for the key"
  sensitive = true
}


output "id" {
  value = garage_key.key.id
  description = "garage key id"
}
