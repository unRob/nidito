terraform {
  backend "consul" {
    path = "nidito/state/service/http-proxy"
  }
}

variable "vault_password" {
  description = "the password to authenticate to vault with as a user"
}

provider "vault" {
  address = "https://vault.service.${terraform.workspace}.consul:5570"
  auth_login {
    path = "auth/userpass/login/rob"
    parameters = {
      password = var.vault_password
      token_ttl = 60
    }
  }
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "http-proxy"
  paths = [
    "tls/*",
    "config/services/ca",
    "config/datacenters/+/dns",
    "config/dns",
    "config/http/zones/*",
    "config/networks",
    "config/networks/*",
  ]
  # nomad_roles = ["http-proxy"]
}

# resource "nomad_acl_policy" "http-proxy" {
#   name        = "http-proxy"
#   description = "Interact with this job's tasks"
#   rules_hcl   = <<HCL
#   namespace "default" {
#     policy = "read"
#     capabilities = [
#       "alloc-exec",
#       "alloc-lifecycle",
#       "list-jobs",
#     ]
#   }
#   HCL
# }

# resource "vault_nomad_secret_role" "http-proxy" {
#   backend   = vault_nomad_secret_backend.config.backend
#   role      = "http-proxy"
#   type      = "client"
#   policies  = ["http-proxy"]
# }
