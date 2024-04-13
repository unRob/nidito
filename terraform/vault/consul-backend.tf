data "terraform_remote_state" "consul" {
  backend   = "consul"
  workspace = "default"
  config = {
    path = "nidito/state/consul"
  }
}

data "consul_acl_token_secret_id" "vault_backend" {
  accessor_id = data.terraform_remote_state.consul.outputs.vault_backend_token
}

resource "vault_consul_secret_backend" "consul" {
  path        = "consul-acl"
  description = "grants consul tokens"

  address = "consul.service.consul:5554"
  scheme  = "https"
  token   = data.consul_acl_token_secret_id.vault_backend.secret_id
}

output "consul_backend_name" {
  value = vault_consul_secret_backend.consul.path
}


// DEPRECATED
resource "vault_mount" "consul" {
  type = "consul"
  path        = "consul"
}
