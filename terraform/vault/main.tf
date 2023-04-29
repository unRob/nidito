terraform {
  backend "consul" {
    path = "nidito/state/vault"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.17.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4.20"
    }
  }

  required_version = ">= 1.0.0"
}

variable "admin_password" {
  description = "the password to set for the admin user"
  sensitive   = true
}


# generic secret provider
resource "vault_mount" "kv" {
  path = "kv"
  type = "kv"
  options = {
    version = 1
  }
}

resource "vault_mount" "nidito" {
  path = "nidito"
  type = "kv"
  options = {
    version = 1
  }
}
