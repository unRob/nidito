
resource "vault_policy" "nomad" {
  name = "nomad-server"

  policy = <<HCL
# from https://www.nomadproject.io/docs/vault-integration
# Allow creating tokens under "nomad-cluster" token role.
path "auth/token/create/nomad-cluster" {
  capabilities = ["update"]
}

# Allow looking up "nomad-cluster" token role. The token role name should be
# updated if "nomad-cluster" is not used.
path "auth/token/roles/nomad-cluster" {
  capabilities = ["read"]
}

# Allow looking up the token passed to Nomad to validate the token has the
# proper capabilities. This is provided by the "default" policy.
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow looking up incoming tokens to validate they have permissions to access
# the tokens they are requesting. This is only required if
# `allow_unauthenticated` is set to false.
path "auth/token/lookup" {
  capabilities = ["update", "read"]
}

# Allow revoking tokens that should no longer exist. This allows revoking
# tokens for dead tasks.
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# Allow checking the capabilities of our own token. This is used to validate the
# token upon startup.
path "sys/capabilities-self" {
  capabilities = ["update"]
}

# Allow our own token to be renewed.
path "auth/token/renew-self" {
  capabilities = ["update"]
}
HCL
}

resource "vault_token_auth_backend_role" "nomad" {
  # https://developer.hashicorp.com/nomad/docs/integrations/vault-integration#token-role-requirements
  role_name           = "nomad-cluster"
  disallowed_policies = [vault_policy.nomad.name]
  orphan              = true
  # 3 days
  token_period           = "259200"
  renewable              = true
  token_explicit_max_ttl = "0"
}

resource "vault_token" "nomad-server" {
  display_name = "nomad-server-token"
  policies     = [vault_policy.nomad.name]
  no_parent    = true
  # one week
  renewable = true
  period    = "168h"
  metadata = {
    "purpose" = "nomad-servers"
  }
}

output "nomad-server-token" {
  value     = vault_token.nomad-server.client_token
  sensitive = true
}


data "external" "nomad-acl" {
  program = ["joao", "get", "${dirname(dirname(path.module))}/../../config/service/nomad.yaml", "acl"]
}

resource "vault_nomad_secret_backend" "nomad-backend" {
  backend                   = "nomad"
  description               = "nomad access for apps"
  default_lease_ttl_seconds = "3600"
  max_lease_ttl_seconds     = "86400"
  max_ttl                   = "86400"
  address                   = "https://nomad.service.${terraform.workspace}.consul:5560"
  token = data.external.nomad-acl.result.secret
}

resource "nomad_acl_policy" "admin" {
  # count = terraform.workspace == "casa" ? 1 : 0
  name        = "admin"
  description = "can do everything"

  # https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-policies#namespace-rules
  rules_hcl = <<-EOF
    namespace "*" {
      policy = "write"
      capabilities = ["alloc-node-exec"]
    }

    node {
      policy = "write"
    }

    agent {
      policy = "write"
    }

    operator {
      policy = "write"
    }

    plugin {
      policy = "read"
    }

    host_volume "*" {
      policy = "write"
    }

  EOF
}

resource "nomad_acl_role" "admins" {
  # count = terraform.workspace == "casa" ? 1 : 0
  name        = "admin"
  description = "cluster admin"

  policy {
    name = nomad_acl_policy.admin.name
  }
}
