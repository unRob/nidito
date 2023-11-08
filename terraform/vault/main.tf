terraform {
  backend "consul" {
    path = "nidito/state/vault"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "vault" {
  address = "https://vault.service.${terraform.workspace}.consul:5570"
}

provider "nomad" {
  address = "https://nomad.service.${terraform.workspace}.consul:5560"
}

variable "admin_password" {
  description = "the password to set for the admin user"
  sensitive   = true
}


resource "vault_mount" "nidito" {
  path = "nidito"
  type = "kv"
  options = {
    version = 1
  }
}
