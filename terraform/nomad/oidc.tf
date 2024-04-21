data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = terraform.workspace
  config = {
    path = "nidito/state/vault"
  }
}

data "vault_generic_secret" "dns" {
  path = "cfg/infra/tree/service:dns"
}

data "vault_generic_secret" "dc" {
  path = "cfg/infra/tree/dc:${terraform.workspace}"
}

# import is broken on vault 4.2.0: https://github.com/hashicorp/terraform-provider-vault/issues/2227
# resource "vault_identity_oidc_client" "nomad" {
#   name = "nomad"
#   # key  = vault_identity_oidc_key.infra.name
#   key = data.terraform_remote_state.vault.outputs.infra_oidc_key.name
#   redirect_uris = flatten([
#     for domain in [
#       "service.consul:5560",
#       nonsensitive(jsondecode(data.vault_generic_secret.dc.data_json).dns.zone),
#       # "${terraform.workspace}.${nonsensitive(data.vault_generic_secret.dns.data.zone)}",
#     ]:
#     [
#       "https://nomad.${domain}/oidc/callback",
#       "https://nomad.${domain}/ui/settings/tokens",
#     ]
#   ])
#   assignments = [
#     data.terraform_remote_state.vault.outputs.admin_oidc_assignment.name
#   ]

#   id_token_ttl     = 2400
#   access_token_ttl = 7200
# }

resource "vault_identity_oidc_scope" "user" {
  name        = "user"
  template    = <<-JSON
    {"username": {{identity.entity.name}}}
  JSON
  description = "The user scope provides claims using Vault identity entity metadata"
}

resource "vault_identity_oidc_scope" "groups" {
  name        = "groups"
  template    = <<-JSON
    {"groups": {{identity.entity.groups.names}}}
  JSON
  description = "The groups scope provides the groups claim using Vault group membership"
}

# resource "vault_identity_oidc_provider" "internal" {
#   name          = "internal"
#   https_enabled = true
#   # issuer_host   = "vault.${terraform.workspace}.${nonsensitive(data.vault_generic_secret.dns.data.zone)}"
#   issuer_host   = "vault.nidi.to"
#   allowed_client_ids = [
#     vault_identity_oidc_client.nomad.client_id
#   ]
#   scopes_supported = [
#     vault_identity_oidc_scope.user.name,
#     vault_identity_oidc_scope.groups.name
#   ]
# }


data "vault_identity_oidc_client_creds" "nomad" {
  name = vault_identity_oidc_client.nomad.name
}


data "vault_identity_oidc_openid_config" "internal" {
  name = vault_identity_oidc_provider.internal.name
}

# resource "nomad_acl_auth_method" "vault-oidc" {
#   name              = "vault"
#   type              = "OIDC"
#   token_locality    = "global"
#   max_token_ttl     = "8h0m0s"
#   default           = false

#   config {
#     oidc_discovery_url    = data.vault_identity_oidc_openid_config.internal.issuer
#     oidc_client_id        = data.vault_identity_oidc_client_creds.nomad.client_id
#     oidc_client_secret    = data.vault_identity_oidc_client_creds.nomad.client_secret
#     oidc_scopes           = ["groups"]
#     bound_audiences       = [data.vault_identity_oidc_client_creds.nomad.client_id]
#     allowed_redirect_uris = vault_identity_oidc_client.nomad.redirect_uris
#     list_claim_mappings = {
#       groups = "roles"
#     }
#   }
# }

resource "nomad_acl_binding_rule" "vault-oidc" {
  auth_method = nomad_acl_auth_method.vault-oidc.name
  selector    = "admin in list.roles"
  bind_type   = "role"
  bind_name   = "admin"
}
