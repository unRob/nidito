terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    b2 = {
      source = "Backblaze/b2"
      version = "~> 0.8.9"
    }
  }
}

data "vault_generic_secret" "backblaze" {
  path = "cfg/infra/tree/provider:backblaze"
}

provider "b2" {
  application_key_id = data.vault_generic_secret.backblaze.data.key
  application_key = data.vault_generic_secret.backblaze.data.secret
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

variable "headers" {
  description = "a map of headers to serve with this bucket"
  default = {}
  type = map(string)
}

variable "cors_rules" {
  type = list(object({
    name = string
    headers = list(string)
    operations = list(string)
    origins = list(string)
    max_age_seconds = number
  }))
  description = "See https://www.backblaze.com/docs/cloud-storage-cross-origin-resource-sharing-rules#cors-rule-structure"
  default = []
}

# https://registry.terraform.io/providers/Backblaze/b2/latest/docs/resources/bucket
resource "b2_bucket" "bucket" {
  bucket_name = var.name
  bucket_type = "all${title(var.acl)}"
  bucket_info = var.headers

  dynamic "cors_rules" {
    for_each = var.cors_rules
    content {
      cors_rule_name = each.name
      allowed_headers = each.headers
      allowed_operations = each.operations
      allowed_origins = each.origins
      max_age_seconds = each.max_age_seconds
    }
  }
}

data "b2_account_info" "info" {
}

output "endpoint" {
  value = replace(data.b2_account_info.info.s3_api_url, "https://", "")
}

output "id" {
  value = b2_bucket.bucket.id
}

output "bucket" {
  value = b2_bucket.bucket.bucket_name
}
