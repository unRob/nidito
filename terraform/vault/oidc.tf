# https://developer.hashicorp.com/nomad/tutorials/single-sign-on/sso-oidc-vault#create-a-vault-oidc-client

resource "vault_identity_oidc_assignment" "admin" {
  name       = "admin"
  entity_ids = [vault_identity_entity.admin.id]
  group_ids  = [vault_identity_group.admin.id]
}

output "admin_oidc_assignment" {
  value = vault_identity_oidc_assignment.admin
}


resource "vault_identity_oidc_key" "infra" {
  name               = "internal"
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
  algorithm          = "RS256"
}

output "infra_oidc_key" {
  value = vault_identity_oidc_key.infra
}
