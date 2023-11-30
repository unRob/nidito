terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    vultr = {
      source = "vultr/vultr"
      version = "~> 2.16.0"
    }

    minio = {
      source = "aminueza/minio"
      version = "~> 2.0.0"
    }
  }
}

variable "object_storage_name" {
  description = "the vultr object storage name to add a bucket to"
  type = string
  default = "bukkit"
}

variable "name" {
  description = "the name of the bucket to create"
  type = string
  validation {
    condition = length(regexall("[^a-z0-9-]+", var.name)) == 0 && length(var.name) <= 63 && length(var.name) >= 3
    error_message = "Bucket name may only contain `a-z`, `0-9`, and `-` and must be between 3 and 63 characters long"
  }
}

variable "acl" {
  description = "the canned ACL rule to apply"
  type = string
  default = "private"
}


data "vault_generic_secret" "vultr" {
  path = "cfg/infra/tree/provider:vultr"
}

provider "vultr" {
  api_key = data.vault_generic_secret.vultr.data.key
}

data "vultr_object_storage" "bukkit" {
  filter {
    name = "label"
    values = [var.object_storage_name]
  }
}

provider "minio" {
  minio_server   = data.vultr_object_storage.bukkit.s3_hostname
  minio_user     = data.vultr_object_storage.bukkit.s3_access_key
  minio_password = data.vultr_object_storage.bukkit.s3_secret_key
  minio_ssl = true
}

resource "minio_s3_bucket" "bucket" {
  bucket = var.name
  acl = var.acl
}

output "endpoint" {
  value = data.vultr_object_storage.bukkit.s3_hostname
}

output "bucket" {
  value = minio_s3_bucket.bucket.id
}
