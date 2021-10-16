terraform {
  backend "consul" {
    path = "nidito/state/vault"
  }

  required_version = ">= 1.0.0"
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

module "dc-policies-casa" {
  count = terraform.workspace == "default" ? 1 : 0
  source = "./policies/casa"
}

module "dc-policies-nyc1" {
  count = terraform.workspace == "nyc1" ? 1 : 0
  source = "./policies/nyc1"
}

module "policies" {
  source = "./policies/shared"
}
