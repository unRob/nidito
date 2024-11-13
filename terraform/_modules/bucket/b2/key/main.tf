terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
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
  description = "the name of the key to create"
  type = string
  validation {
    condition = length(regexall("[^a-z0-9-]+", var.name)) == 0 && length(var.name) <= 63 && length(var.name) >= 3
    error_message = "key name may only contain `a-z`, `0-9`, and `-` and must be between 3 and 63 characters long"
  }
}

variable "bucket_id" {
  description = "the bucket_id to associate to this key"
  type = string
  default = ""
}

variable "capabilities" {
  description = "list of b2 api capabilities for this key"
  type = list(string)
  default = ["listAllBucketNames", "listFiles", "readBuckets", "readFiles"]
  validation {
    condition = alltrue([for v in var.capabilities: contains( ["listKeys", "writeKeys", "deleteKeys", "listAllBucketNames", "listBuckets", "readBuckets", "writeBuckets", "deleteBuckets", "readBucketRetentions", "writeBucketRetentions", "readBucketEncryption", "writeBucketEncryption", "listFiles", "readFiles", "shareFiles", "writeFiles", "deleteFiles", "readFileLegalHolds", "writeFileLegalHolds", "readFileRetentions", "writeFileRetentions", "bypassGovernance" ], v)])
    error_message = "Unknown capabilities, allowed ones are [listKeys, writeKeys, deleteKeys, listAllBucketNames, listBuckets, readBuckets, writeBuckets, deleteBuckets, readBucketRetentions, writeBucketRetentions, readBucketEncryption, writeBucketEncryption, listFiles, readFiles, shareFiles, writeFiles, deleteFiles, readFileLegalHolds, writeFileLegalHolds, readFileRetentions, writeFileRetentions, bypassGovernance]"
  }
}

# see https://www.backblaze.com/apidocs/b2-create-key
resource "b2_application_key" "key" {
  key_name = var.name
  capabilities = var.capabilities
  bucket_id = var.bucket_id
}

output "credentials" {
  value = {
    key = b2_application_key.key.application_key_id
    secret = b2_application_key.key.application_key
  }
  description = "credentials for the key"
  sensitive = true
}

output "id" {
  value = b2_application_key.key.id
  description = "b2 key id"
}
