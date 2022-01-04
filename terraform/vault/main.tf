terraform {
  backend "consul" {
    path = "nidito/state/vault"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

variable "admin_password" {
  description = "the password to set for the admin user"
  sensitive = true
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

# consul provider
resource "vault_mount" "consul" {
  path = "consul"
  type = "consul"
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
  path = "userpass"
  description = "username and password for humans"
}

# username auth
resource "vault_generic_endpoint" "admin" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/rob"
  ignore_absent_fields = true

  data_json = jsonencode({
    policies = ["admin"]
    password = var.admin_password
  })
}
