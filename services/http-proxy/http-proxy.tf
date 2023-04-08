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
  paths = ["tls/*"]

  configs = [
    "service:ca",
    "dc:*",
    "service:dns",
    "net:*",
  ]
}
