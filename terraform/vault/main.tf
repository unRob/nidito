terraform {
  backend "consul" {
    path    = "nidito/state/vault"
  }

  required_version = ">= 0.12.0"
}

# generic secret provider
resource vault_mount kv {
  path        = "kv"
  type        = "kv"
  options = {
    version = 1
  }
}

# consul provider
resource vault_mount consul {
  path        = "consul"
  type        = "consul"
}

