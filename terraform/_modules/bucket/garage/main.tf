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

variable "website_access" {
  description = "enable website access"
  type = bool
  default = false
}

variable "grants" {
  description = "the grants to apply, read enabled by default"
  type = map(object({
    key_id = string
    write = bool
  }))
  default = {}
}

provider "garage" {
  host = "api.garage.nidi.to"
  scheme = "https"
  token = jsondecode(data.vault_generic_secret.garage.data.token).admin
}

data "vault_generic_secret" "garage" {
  path = "cfg/svc/tree/nidi.to:garage"
}

resource "garage_bucket" "bucket" {
  website_access_enabled = var.website_access
  website_config_error_document = var.website_access ? "error.html" : ""
  website_config_index_document = var.website_access ? "index.html" : ""
}

resource "garage_bucket_global_alias" "alias" {
  bucket_id = garage_bucket.bucket.id
  alias     = var.name
}

resource "garage_bucket_key" "bucket_grant" {
  for_each      = var.grants
  bucket_id     = garage_bucket.bucket.id
  access_key_id = each.value.key_id
  read          = true
  write         = each.value.write
}

output "bucket" {
  value = garage_bucket.bucket.id
  description = "the bucket id"
}

